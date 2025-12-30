# Schema bazei de date PostgreSQL pentru referaturl "Securitatea Bazelor de Date - PostgreSQL"

Pentru referatul acesta (care va vi implementat în continuare pentru aplicația de evaluare SBD) o să mă folosesc de un DB Schema simplu compus de 3 entitățiȘ
- pacient
- personal_meidcal
- fișă_medicală

Relațiile sunt următoarele:
- Pacient (1) ------- (N) Fișă_medicală
- Personal_medical (1) ------- (N) Fișă_medicală

