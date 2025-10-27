package main

import (
	"context"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"vinylhound/shared/middleware"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// Validate required environment variables
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		log.Fatal("JWT_SECRET environment variable is required")
	}

	// Service URLs
	userServiceURL := getEnv("USER_SERVICE_URL", "http://localhost:8001")
	catalogServiceURL := getEnv("CATALOG_SERVICE_URL", "http://localhost:8002")
	ratingServiceURL := getEnv("RATING_SERVICE_URL", "http://localhost:8003")
	playlistServiceURL := getEnv("PLAYLIST_SERVICE_URL", "http://localhost:8004")

	// Create reverse proxies
	userProxy := createProxy(userServiceURL)
	catalogProxy := createProxy(catalogServiceURL)
	ratingProxy := createProxy(ratingServiceURL)
	playlistProxy := createProxy(playlistServiceURL)

	// Setup router
	router := mux.NewRouter()

	// Add CORS middleware (applied to all routes)
	router.Use(middleware.CORS(middleware.DefaultCORSConfig()))

	// Health check (public endpoint - no auth required)
	router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	}).Methods("GET")

	// Public API routes (no authentication required)
	publicAPI := router.PathPrefix("/api/v1").Subrouter()

	// Authentication endpoints (signup, login) - public
	publicAPI.PathPrefix("/auth/signup").Handler(userProxy)
	publicAPI.PathPrefix("/auth/login").Handler(userProxy)

	// Public catalog browsing - anyone can view albums
	publicAPI.PathPrefix("/albums").Handler(catalogProxy).Methods("GET", "OPTIONS")
	publicAPI.PathPrefix("/artists").Handler(catalogProxy).Methods("GET", "OPTIONS")
	publicAPI.PathPrefix("/songs").Handler(catalogProxy).Methods("GET", "OPTIONS")
	publicAPI.PathPrefix("/catalog").Handler(catalogProxy).Methods("GET", "OPTIONS")

	// Protected API routes (authentication required)
	protectedAPI := router.PathPrefix("/api/v1").Subrouter()
	protectedAPI.Use(authenticationMiddleware())

	// User management (protected)
	protectedAPI.PathPrefix("/users").Handler(userProxy)
	protectedAPI.PathPrefix("/me").Handler(userProxy)

	// Album management - write operations require auth
	protectedAPI.PathPrefix("/albums").Handler(catalogProxy).Methods("POST", "PUT", "DELETE")
	protectedAPI.PathPrefix("/artists").Handler(catalogProxy).Methods("POST", "PUT", "DELETE")
	protectedAPI.PathPrefix("/songs").Handler(catalogProxy).Methods("POST", "PUT", "DELETE")

	// Rating and review service (all operations protected)
	protectedAPI.PathPrefix("/ratings").Handler(ratingProxy)
	protectedAPI.PathPrefix("/reviews").Handler(ratingProxy)
	protectedAPI.PathPrefix("/preferences").Handler(ratingProxy)

	// Playlist service (all operations protected)
	protectedAPI.PathPrefix("/playlists").Handler(playlistProxy)

	// Start server
	port := getEnv("PORT", "8080")
	server := &http.Server{
		Addr:         ":" + port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Printf("API Gateway starting on port %s", port)
		log.Printf("User Service: %s", userServiceURL)
		log.Printf("Catalog Service: %s", catalogServiceURL)
		log.Printf("Rating Service: %s", ratingServiceURL)
		log.Printf("Playlist Service: %s", playlistServiceURL)
		log.Printf("Authentication: ENABLED")

		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

// authenticationMiddleware validates the Authorization header
// Note: This is a basic implementation that checks for Bearer token presence
// In production, you should validate tokens against the user service or database
func authenticationMiddleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Extract token from Authorization header
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, `{"error":"Missing authorization header"}`, http.StatusUnauthorized)
				w.Header().Set("Content-Type", "application/json")
				return
			}

			// Check for Bearer token format
			if !strings.HasPrefix(authHeader, "Bearer ") {
				http.Error(w, `{"error":"Invalid authorization format. Expected: Bearer <token>"}`, http.StatusUnauthorized)
				w.Header().Set("Content-Type", "application/json")
				return
			}

			token := strings.TrimPrefix(authHeader, "Bearer ")
			if token == "" {
				http.Error(w, `{"error":"Missing token"}`, http.StatusUnauthorized)
				w.Header().Set("Content-Type", "application/json")
				return
			}

			// Token validation is delegated to backend services
			// The gateway only validates presence and format
			// Backend services should validate token authenticity

			next.ServeHTTP(w, r)
		})
	}
}

func createProxy(targetURL string) *httputil.ReverseProxy {
	target, err := url.Parse(targetURL)
	if err != nil {
		log.Fatalf("Invalid target URL %s: %v", targetURL, err)
	}

	proxy := httputil.NewSingleHostReverseProxy(target)

	// Add error handler for upstream failures
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		log.Printf("Proxy error for %s: %v", r.URL.Path, err)
		w.Header().Set("Content-Type", "application/json")
		http.Error(w, `{"error":"Service temporarily unavailable"}`, http.StatusBadGateway)
	}

	return proxy
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
