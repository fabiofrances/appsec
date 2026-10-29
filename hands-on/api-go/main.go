// API de IMC em Go — mesmo contrato do backend NestJS, só com a stdlib.
// Existe para o hands-on de containers: binário estático que roda em scratch.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	// scratch/distroless não têm wget/curl: o próprio binário faz o healthcheck.
	healthcheck := flag.Bool("healthcheck", false, "faz GET /health e sai com 0 (ok) ou 1")
	flag.Parse()

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	if *healthcheck {
		os.Exit(runHealthcheck("http://127.0.0.1:" + port + "/health"))
	}

	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           newRouter(),
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		log.Printf("bmi-api-go ouvindo em :%s", port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	}()

	// PID 1 no container: tratar SIGTERM para o "docker stop" não esperar 10s
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, os.Interrupt)
	defer stop()
	<-ctx.Done()

	log.Println("encerrando...")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdownCtx)
}

func newRouter() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /bmi/calculate", handleCalculate)
	mux.HandleFunc("GET /health", handleHealth)
	return mux
}

func handleCalculate(w http.ResponseWriter, r *http.Request) {
	var req BmiRequest
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"statusCode": http.StatusBadRequest, "message": []string{"invalid JSON body"}, "error": "Bad Request",
		})
		return
	}
	if errs := req.Validate(); len(errs) > 0 {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"statusCode": http.StatusBadRequest, "message": errs, "error": "Bad Request",
		})
		return
	}
	result, _ := Calculate(req)
	writeJSON(w, http.StatusCreated, result)
}

func handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"status": "ok"})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func runHealthcheck(url string) int {
	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return 1
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}
