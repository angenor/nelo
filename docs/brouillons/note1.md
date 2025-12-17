# Lancer l'environnement de developpement
docker compose -f docker-compose.dev.yml up --build

# Verifier
curl http://localhost:8000/health
curl http://localhost:8000/health/ready
