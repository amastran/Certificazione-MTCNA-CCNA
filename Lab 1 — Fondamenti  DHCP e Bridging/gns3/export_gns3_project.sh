#!/bin/bash
# ============================================================
# export_gns3_project.sh
# Esporta il progetto GNS3 Lab 1 MTCNA come portable project
# Eseguire questo script DAL TUO PC (non dal server GNS3)
# ============================================================

GNS3_URL="http://192.168.28.90:3080"
PROJECT_ID="6c00e09d-f4ee-42f9-bbda-62b735c90c87"
OUTPUT_FILE="MTCNA_Lab1_GNS3_portable.zip"

echo "Esportazione progetto GNS3..."
echo "Server  : $GNS3_URL"
echo "Progetto: $PROJECT_ID"
echo "Output  : $OUTPUT_FILE"
echo ""

# Export portable (include topology + disk images)
# ATTENZIONE: può richiedere diversi minuti se le immagini sono grandi
curl -s -o "$OUTPUT_FILE" \
  "$GNS3_URL/v2/projects/$PROJECT_ID/export"

if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
    SIZE=$(du -sh "$OUTPUT_FILE" | cut -f1)
    echo "OK — File creato: $OUTPUT_FILE ($SIZE)"
else
    echo "ERRORE — Verifica che il server GNS3 sia avviato e il PROJECT_ID sia corretto"
    rm -f "$OUTPUT_FILE"
    exit 1
fi

# --- Export solo topology (senza disk images, più leggero) ---
# Decommentare per esportare solo la topologia .gns3 (JSON):
#
# curl -s "$GNS3_URL/v2/projects/$PROJECT_ID" | jq . > MTCNA_Lab1_topology.json
#
# Oppure scarica il file .gns3 direttamente dal filesystem del server:
# scp user@192.168.28.90:/opt/gns3/projects/$PROJECT_ID/*.gns3 .
