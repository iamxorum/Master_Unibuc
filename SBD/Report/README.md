# Referat "Securitatea Bazelor de Date - PostgreSQL"

# Schema bazei de date

Pentru referatul acesta (care va vi implementat în continuare pentru aplicația de evaluare SBD) o să mă folosesc de un DB Schema simplu compus de 3 entitățiȘ
- pacient
- personal_meidcal
- fișă_medicală

Relațiile sunt următoarele:
- Pacient (1) ------- (N) Fișă_medicală
- Personal_medical (1) ------- (N) Fișă_medicală

# Securitatea rețelei

Primul pas pentru securizarea bazei de date este de a stabili cine și cum poate accesa baza de date prin intermediul fișierului pg_gba.conf unde acolo se stabilește ce range-uri de IP sunt granted sau rejected pentru acces (Este practica bună să fie securizat la nivel de firewall acces-ul dar este bine să existe un onion layer în cazul în care firewall-ul nu mai funcționează).

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             10.80.0.0/16            scram-sha-256
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
```

Asta este o configurație minimală care permite acces-ul la baza de date in local cu parolă de autentificare; permite access-ul prin parola la userii care provin din range-ul de IP 10.80.0.0/16 (VPN in cazul acesta) și localhost; în final se dă reject la restul userilor care provin de altundeva la nivelul IPv4 și IPv6.

O vulnerabilitate era să fie trecut pentru tipul de conexiune `local` metoda `trust` unde se permitea conexiunea fară parolă.

O altă vulnerabilitate era folosirea metodei `md5` în loc de `scram-sha-256` deoarece md5 este mai nesigur (și-a pierdut setarea by default de la postgreSQL 14 unde scram-sha-256 este acum setat default).

MD5 ca să fie considerat sigur trebuie să îndeplineasca următoarele:
- Ar trebui să fie capabil să convertească ușor informații digitale, cum ar fi un mesaj, într-o valoare hash cu lungime fixă.
- Hash-ul trebuie să fie imposibil de decriptat din punct de vedere computational pentru a obține orice informații despre mesajul de intrare.
- Din punct de vedere computational, trebuie săe fie imposibil să se găsească două fișiere cu un hash identic.

Din păcate al treilea punct nu este îndeplinit deoarece este posibil să se genereze același hash pentru două fișiere diferite; situația asta aduce la atacuri de tip coliziune, o vulneraibilitate extrem de ridicată, deoarece pot sa generez acelasi hash pentru o altă parolă spre exemplu.
https://repo.zenk-security.com/Cryptographie%20.%20Algorithmes%20.%20Steganographie/MD5%20Collisions.pdf

O altă metodă buna pentru securizarea accesului prin rețea este setarea tipului de conexiune in loc de `host` cu `hostssl`. Pentru referat nu vom folosi SSL.

Conexiune prin hostssl (eșec)
![hostssl Activat](./assets/hostssl.png)

Conexiune prin host (success)
![hostssl Dezactivat](./assets/host.png)