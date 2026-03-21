package main

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

var (
	mu        sync.Mutex
	storedFP  string
	storedKey string
	storedAt  time.Time
)

func fingerprint(c *x509.Certificate) string {
	h := sha256.Sum256(c.Raw)
	return fmt.Sprintf("%x", h)
}

func main() {
	unlockAddr := flag.String("unlock-addr", "", "unlock listen IP")
	registerAddr := flag.String("register-addr", "", "register listen IP")
	port := flag.Int("port", 9735, "listen port for both services")
	certFile := flag.String("cert", "", "server TLS cert")
	keyFile := flag.String("key", "", "server TLS key")
	ttl := flag.Int("ttl", 300, "entry TTL seconds")
	flag.Parse()

	if *unlockAddr == "" || *registerAddr == "" || *certFile == "" || *keyFile == "" {
		log.Fatal("--unlock-addr, --register-addr, --cert and --key are required")
	}

	portStr := fmt.Sprintf(":%d", *port)
	ttlDur := time.Duration(*ttl) * time.Second

	log.Printf("unlock listener: %s%s", *unlockAddr, portStr)
	log.Printf("register listener: %s%s", *registerAddr, portStr)
	log.Printf("TTL: %s", ttlDur)

	registerMux := http.NewServeMux()
	registerMux.HandleFunc("/register/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		fp := strings.TrimPrefix(r.URL.Path, "/register/")
		if len(fp) != 64 {
			http.Error(w, "bad fingerprint", http.StatusBadRequest)
			return
		}

		mu.Lock()
		storedFP, storedKey, storedAt = fp, rand.Text(), time.Now()
		mu.Unlock()
		log.Printf("register: fingerprint=%s from=%s", fp, r.RemoteAddr)

		w.Header().Set("Content-Type", "application/octet-stream")
		w.Write([]byte(storedKey))
	})

	// GET /unlock
	// Verifies the ephemeral cert fingerprint matches hasn't expired
	// Replies with the stored key
	unlockMux := http.NewServeMux()
	unlockMux.HandleFunc("/unlock", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		cert := r.TLS.PeerCertificates[0]
		remoteIP, _, _ := net.SplitHostPort(r.RemoteAddr)
		if len(cert.IPAddresses) == 0 || cert.IPAddresses[0].String() != remoteIP {
			log.Printf("unlock: rejected, IP mismatch: cert=%v remote=%s", cert.IPAddresses, remoteIP)
			http.Error(w, "IP mismatch", http.StatusForbidden)
			return
		}
		fp := fingerprint(cert)
		log.Printf("unlock: remote=%s cert_ip=%v fingerprint=%s", remoteIP, cert.IPAddresses, fp)

		mu.Lock()
		if storedFP != fp {
			mu.Unlock()
			log.Printf("unlock: rejected, fingerprint mismatch (have=%s)", storedFP)
			http.Error(w, "fingerprint mismatch", http.StatusForbidden)
			return
		}
		if time.Since(storedAt) > ttlDur {
			storedFP, storedKey = "", ""
			mu.Unlock()
			log.Printf("unlock: rejected, entry expired (age=%s)", time.Since(storedAt))
			http.Error(w, "entry expired", http.StatusForbidden)
			return
		}
		key := storedKey
		storedFP, storedKey = "", ""
		mu.Unlock()

		log.Printf("unlock: success, key dispensed to %s", remoteIP)
		w.Header().Set("Content-Type", "application/octet-stream")
		w.Write([]byte(key))
	})

	go func() { log.Fatal(http.ListenAndServeTLS(*registerAddr+portStr, *certFile, *keyFile, registerMux)) }()

	tlsCert, err := tls.LoadX509KeyPair(*certFile, *keyFile)
	if err != nil {
		log.Fatalf("cert: %v", err)
	}

	log.Fatal((&http.Server{
		Addr:    *unlockAddr + portStr,
		Handler: unlockMux,
		TLSConfig: &tls.Config{
			Certificates: []tls.Certificate{tlsCert},
			ClientAuth:   tls.RequireAnyClientCert,
			MinVersion:   tls.VersionTLS13,
		},
	}).ListenAndServeTLS("", ""))
}
