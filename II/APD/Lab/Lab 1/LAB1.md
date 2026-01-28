# Lab 1 - Algoritmi Paraleli și Distribuiți

Buna seara domnule profesor, stiu ca am trecut de deadline :)
Imi cer scuze, am incercat si eu sa fac ce am putut, am fost aglomerat cu lucrul saptamanile astea.

Cu stima,
Murariu Andrei
BDTS

## Test mpi4py

Am instalat (prin virtual environment pe mac) și testat pachetul `mpi4py` pentru Python. Testul demonstrează:
- Inițializarea MPI și obținerea rank-ului procesului
- Comunicarea point-to-point între procese (send/recv)
- Sincronizarea cu Barrier()

Programul a rulat cu succes pe un singur proces, confirmând configurarea corectă a mediului MPI. Pentru testarea comunicării între procese multiple, se poate folosi `mpiexec -n 4 python3 test_mpi.py`.

**Barrier() dezactivat** - Procesele rulează independent, mesajele apar în ordine aleatorie

```bash
$ mpiexec -n 4 python3 test_mpi.py
Procesul 1 din 4 procese active

=== Procesul SLAVE (rank 1) ===
Am primit mesaj: Mesaj pentru procesul 1!
Am trimis răspuns către master
Procesul 2 din 4 procese active

=== Procesul SLAVE (rank 2) ===
Am primit mesaj: Mesaj pentru procesul 2!
Am trimis răspuns către master
Procesul 0 din 4 procese active

=== Procesul MASTER (rank 0) ===
Total procese: 4
Am trimis mesaj către procesul 1
Am trimis mesaj către procesul 2
Am trimis mesaj către procesul 3
Răspuns de la procesul 1: Procesul 1 a primit mesajul!
Răspuns de la procesul 2: Procesul 2 a primit mesajul!
Răspuns de la procesul 3: Procesul 3 a primit mesajul!

=== Test completat cu succes! ===
Toate procesele au terminat execuția.
Procesul 3 din 4 procese active

=== Procesul SLAVE (rank 3) ===
Am primit mesaj: Mesaj pentru procesul 3!
Am trimis răspuns către master
```

**Barrier() activat** - Toate procesele se sincronizează, mesajele apar grupat

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1
$ mpiexec -n 4 python3 test_mpi.py
Procesul 0 din 4 procese active

=== Procesul MASTER (rank 0) ===
Total procese: 4
Am trimis mesaj către procesul 1
Am trimis mesaj către procesul 2
Am trimis mesaj către procesul 3
Răspuns de la procesul 1: Procesul 1 a primit mesajul!
Răspuns de la procesul 2: Procesul 2 a primit mesajul!
Răspuns de la procesul 3: Procesul 3 a primit mesajul!

=== Test completat cu succes! ===
Toate procesele au terminat execuția.
Procesul 1 din 4 procese active

=== Procesul SLAVE (rank 1) ===
Am primit mesaj: Mesaj pentru procesul 1!
Am trimis răspuns către master
Procesul 2 din 4 procese active

=== Procesul SLAVE (rank 2) ===
Am primit mesaj: Mesaj pentru procesul 2!
Am trimis răspuns către master
Procesul 3 din 4 procese active

=== Procesul SLAVE (rank 3) ===
Am primit mesaj: Mesaj pentru procesul 3!
Am trimis răspuns către master
```

## Tutorial
### Comunicare Point-to-Point

**py_objects.py** - Demonstrează trimiterea obiectelor Python complexe (dicționar) între procese folosind `send()` și `recv()` cu tag-uri specifice.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/p2p
$ mpiexec -n 4 python3 py_objects.py 
Procesul 0: trimit datele {'a': 7, 'b': 3.14}
Procesul 0: datele au fost trimise
Procesul 1: aștept să primesc date
Procesul 1: am primit datele {'a': 7, 'b': 3.14}
```

**py_objects_non_blocking.py** - Demonstrează comunicarea non-blocking cu `isend()` și `irecv()` care returnează request objects pentru control asincron.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/p2p
$ mpiexec -n 4 python3 py_objects_non_blocking.py 
Procesul 0: încep trimiterea non-blocking a datelor {'a': 7, 'b': 3.14}
Procesul 0: aștept finalizarea trimiterii
Procesul 0: trimiterea s-a finalizat
Procesul 1: încep primirea non-blocking
Procesul 1: aștept finalizarea primirii
Procesul 1: am primit datele {'a': 7, 'b': 3.14}
```

**py_objects_numpy.py** - Demonstrează comunicarea array-urilor NumPy cu tipuri MPI explicite (`Send([data, MPI.INT])`) și auto-detectare (`Send(data)`).

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/p2p
$ mpiexec -n 4 python3 py_objects_numpy.py 
Procesul 0: trimit array numpy cu tip explicit MPI.INT
Procesul 0: array trimis cu succes
Procesul 0: trimit array numpy cu auto-detectare tip
Procesul 0: array auto-detectat trimis
Procesul 1: primesc array cu tip explicit MPI.INT
Procesul 1: am primit array-ul, primul element: 0
Procesul 1: primesc array cu auto-detectare tip
Procesul 1: am primit array auto-detectat, primul element: 0.0
```
### Comunicare Colectiva

**dict_broadcast.py** - Demonstrează operația de broadcast (`bcast()`) prin care procesul root trimite aceleași date către toate celelalte procese.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 4 python3 dict_broadcast.py 
Procesul 0: pregătesc datele pentru broadcast: {'key1': [7, 2.72, (2+3j)], 'key2': ('abc', 'xyz')}
Procesul 0: încep broadcast
Procesul 0: am primit datele prin broadcast: {'key1': [7, 2.72, (2+3j)], 'key2': ('abc', 'xyz')}
Procesul 1: aștept să primesc date prin broadcast
Procesul 1: încep broadcast
Procesul 1: am primit datele prin broadcast: {'key1': [7, 2.72, (2+3j)], 'key2': ('abc', 'xyz')}
Procesul 2: aștept să primesc date prin broadcast
Procesul 2: încep broadcast
Procesul 2: am primit datele prin broadcast: {'key1': [7, 2.72, (2+3j)], 'key2': ('abc', 'xyz')}
Procesul 3: aștept să primesc date prin broadcast
Procesul 3: încep broadcast
Procesul 3: am primit datele prin broadcast: {'key1': [7, 2.72, (2+3j)], 'key2': ('abc', 'xyz')}
```

**obj_scattering.py** - Demonstrează operația de scatter (`scatter()`) prin care procesul root distribuie diferite părți din date către fiecare proces.

```bash
amxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 2 python3 obj_scattering.py 
Procesul 0: pregătesc datele pentru scatter: [1, 4]
Procesul 0: încep scatter
Procesul 0: am primit partea mea prin scatter: 1
Procesul 0: verificare reușită - 1 == 1
Procesul 1: aștept să primesc o parte din date prin scatter
Procesul 1: încep scatter
Procesul 1: am primit partea mea prin scatter: 4
Procesul 1: verificare reușită - 4 == 4
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 4 python3 obj_scattering.py 
Procesul 0: pregătesc datele pentru scatter: [1, 4, 9, 16]
Procesul 0: încep scatter
Procesul 0: am primit partea mea prin scatter: 1
Procesul 0: verificare reușită - 1 == 1
Procesul 1: aștept să primesc o parte din date prin scatter
Procesul 1: încep scatter
Procesul 1: am primit partea mea prin scatter: 4
Procesul 1: verificare reușită - 4 == 4
Procesul 2: aștept să primesc o parte din date prin scatter
Procesul 2: încep scatter
Procesul 2: am primit partea mea prin scatter: 9
Procesul 2: verificare reușită - 9 == 9
Procesul 3: aștept să primesc o parte din date prin scatter
Procesul 3: încep scatter
Procesul 3: am primit partea mea prin scatter: 16
Procesul 3: verificare reușită - 16 == 16
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 6 python3 obj_scattering.py 
Procesul 0: pregătesc datele pentru scatter: [1, 4, 9, 16, 25, 36]
Procesul 0: încep scatter
Procesul 0: am primit partea mea prin scatter: 1
Procesul 0: verificare reușită - 1 == 1
Procesul 1: aștept să primesc o parte din date prin scatter
Procesul 1: încep scatter
Procesul 1: am primit partea mea prin scatter: 4
Procesul 1: verificare reușită - 4 == 4
Procesul 4: aștept să primesc o parte din date prin scatter
Procesul 4: încep scatter
Procesul 4: am primit partea mea prin scatter: 25
Procesul 4: verificare reușită - 25 == 25
Procesul 5: aștept să primesc o parte din date prin scatter
Procesul 5: încep scatter
Procesul 5: am primit partea mea prin scatter: 36
Procesul 5: verificare reușită - 36 == 36
Procesul 2: aștept să primesc o parte din date prin scatter
Procesul 2: încep scatter
Procesul 2: am primit partea mea prin scatter: 9
Procesul 2: verificare reușită - 9 == 9
Procesul 3: aștept să primesc o parte din date prin scatter
Procesul 3: încep scatter
Procesul 3: am primit partea mea prin scatter: 16
Procesul 3: verificare reușită - 16 == 16
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 8 python3 obj_scattering.py 
Procesul 0: pregătesc datele pentru scatter: [1, 4, 9, 16, 25, 36, 49, 64]
Procesul 0: încep scatter
Procesul 0: am primit partea mea prin scatter: 1
Procesul 0: verificare reușită - 1 == 1
Procesul 2: aștept să primesc o parte din date prin scatter
Procesul 2: încep scatter
Procesul 2: am primit partea mea prin scatter: 9
Procesul 2: verificare reușită - 9 == 9
Procesul 3: aștept să primesc o parte din date prin scatter
Procesul 3: încep scatter
Procesul 3: am primit partea mea prin scatter: 16
Procesul 3: verificare reușită - 16 == 16
Procesul 4: aștept să primesc o parte din date prin scatter
Procesul 4: încep scatter
Procesul 4: am primit partea mea prin scatter: 25
Procesul 4: verificare reușită - 25 == 25
Procesul 5: aștept să primesc o parte din date prin scatter
Procesul 5: încep scatter
Procesul 5: am primit partea mea prin scatter: 36
Procesul 5: verificare reușită - 36 == 36
Procesul 1: aștept să primesc o parte din date prin scatter
Procesul 1: încep scatter
Procesul 1: am primit partea mea prin scatter: 4
Procesul 1: verificare reușită - 4 == 4
Procesul 6: aștept să primesc o parte din date prin scatter
Procesul 6: încep scatter
Procesul 6: am primit partea mea prin scatter: 49
Procesul 6: verificare reușită - 49 == 49
Procesul 7: aștept să primesc o parte din date prin scatter
Procesul 7: încep scatter
Procesul 7: am primit partea mea prin scatter: 64
Procesul 7: verificare reușită - 64 == 64
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 10 python3 obj_scattering.py 
Procesul 0: pregătesc datele pentru scatter: [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
Procesul 0: încep scatter
Procesul 0: am primit partea mea prin scatter: 1
Procesul 0: verificare reușită - 1 == 1
Procesul 1: aștept să primesc o parte din date prin scatter
Procesul 1: încep scatter
Procesul 1: am primit partea mea prin scatter: 4
Procesul 1: verificare reușită - 4 == 4
Procesul 4: aștept să primesc o parte din date prin scatter
Procesul 4: încep scatter
Procesul 4: am primit partea mea prin scatter: 25
Procesul 4: verificare reușită - 25 == 25
Procesul 2: aștept să primesc o parte din date prin scatter
Procesul 2: încep scatter
Procesul 2: am primit partea mea prin scatter: 9
Procesul 2: verificare reușită - 9 == 9
Procesul 3: aștept să primesc o parte din date prin scatter
Procesul 3: încep scatter
Procesul 3: am primit partea mea prin scatter: 16
Procesul 3: verificare reușită - 16 == 16
Procesul 5: aștept să primesc o parte din date prin scatter
Procesul 5: încep scatter
Procesul 5: am primit partea mea prin scatter: 36
Procesul 5: verificare reușită - 36 == 36
Procesul 6: aștept să primesc o parte din date prin scatter
Procesul 6: încep scatter
Procesul 6: am primit partea mea prin scatter: 49
Procesul 6: verificare reușită - 49 == 49
Procesul 7: aștept să primesc o parte din date prin scatter
Procesul 7: încep scatter
Procesul 7: am primit partea mea prin scatter: 64
Procesul 7: verificare reușită - 64 == 64
Procesul 8: aștept să primesc o parte din date prin scatter
Procesul 8: încep scatter
Procesul 8: am primit partea mea prin scatter: 81
Procesul 8: verificare reușită - 81 == 81
Procesul 9: aștept să primesc o parte din date prin scatter
Procesul 9: încep scatter
Procesul 9: am primit partea mea prin scatter: 100
Procesul 9: verificare reușită - 100 == 100
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ 
```

**obj_gathering.py** - Demonstrează operația de gather (`gather()`) prin care procesul root colectează date de la toate celelalte procese.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 4 python3 obj_gathering.py 
Procesul 1: pregătesc datele pentru gather: 4
Procesul 1: încep gather
Procesul 1: gather completat, data este None
Procesul 2: pregătesc datele pentru gather: 9
Procesul 2: încep gather
Procesul 2: gather completat, data este None
Procesul 3: pregătesc datele pentru gather: 16
Procesul 3: încep gather
Procesul 3: gather completat, data este None
Procesul 0: pregătesc datele pentru gather: 1
Procesul 0: încep gather
Procesul 0: am primit toate datele prin gather: [1, 4, 9, 16]
Procesul 0: verificare reușită pentru procesul 0 - 1 == 1
Procesul 0: verificare reușită pentru procesul 1 - 4 == 4
Procesul 0: verificare reușită pentru procesul 2 - 9 == 9
Procesul 0: verificare reușită pentru procesul 3 - 16 == 16
```

**numpy_broadcast.py** - Demonstrează broadcast-ul array-urilor NumPy folosind `Bcast()` pentru comunicare eficientă a datelor numerice.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 4 python3 numpy_broadcast.py 
Procesul 0: pregătesc array numpy pentru broadcast: primul element 0, ultimul element 99
Procesul 0: încep broadcast
Procesul 0: broadcast completat, verific array-ul
Procesul 0: verificare reușită - toate elementele sunt corecte
Procesul 1: pregătesc array gol pentru primirea datelor prin broadcast
Procesul 1: încep broadcast
Procesul 1: broadcast completat, verific array-ul
Procesul 1: verificare reușită - toate elementele sunt corecte
Procesul 2: pregătesc array gol pentru primirea datelor prin broadcast
Procesul 2: încep broadcast
Procesul 2: broadcast completat, verific array-ul
Procesul 2: verificare reușită - toate elementele sunt corecte
Procesul 3: pregătesc array gol pentru primirea datelor prin broadcast
Procesul 3: încep broadcast
Procesul 3: broadcast completat, verific array-ul
Procesul 3: verificare reușită - toate elementele sunt corecte
```

**numpy_scattering.py** - Demonstrează scatter-ul array-urilor NumPy folosind `Scatter()` pentru distribuția eficientă a datelor numerice.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 6 python3 numpy_scattering.py 
Procesul 0: pregătesc matricea pentru scatter - dimensiuni (6, 100)
Procesul 0: primul rând: [0 0 0 0 0]...
Procesul 0: încep scatter
Procesul 0: scatter completat, verific array-ul primit
Procesul 0: verificare reușită - toate elementele sunt 0
Procesul 1: nu sunt root, nu pregătesc matricea
Procesul 1: încep scatter
Procesul 1: scatter completat, verific array-ul primit
Procesul 1: verificare reușită - toate elementele sunt 1
Procesul 4: nu sunt root, nu pregătesc matricea
Procesul 4: încep scatter
Procesul 4: scatter completat, verific array-ul primit
Procesul 4: verificare reușită - toate elementele sunt 4
Procesul 5: nu sunt root, nu pregătesc matricea
Procesul 5: încep scatter
Procesul 5: scatter completat, verific array-ul primit
Procesul 5: verificare reușită - toate elementele sunt 5
Procesul 2: nu sunt root, nu pregătesc matricea
Procesul 2: încep scatter
Procesul 2: scatter completat, verific array-ul primit
Procesul 2: verificare reușită - toate elementele sunt 2
Procesul 3: nu sunt root, nu pregătesc matricea
Procesul 3: încep scatter
Procesul 3: scatter completat, verific array-ul primit
Procesul 3: verificare reușită - toate elementele sunt 3
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ 
```

**parallel_mv.py** - Demonstrează înmulțirea paralelă matrice-vector folosind `Allgather()` pentru colectarea vectorului complet și calculul distribuit.

Diferențele între rularea cu 2 și 4 procese arată scalabilitatea algoritmului: cu mai multe procese, dimensiunea problemei crește (matricea 2×4 → 2×8), dar overhead-ul de comunicare prin Allgather crește proporțional. Diferenta intre 2 si 4 procese.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 2 python3 parallel_mv.py 
Procesul 0: testez înmulțirea matrice-vector paralelă
Procesul 0: matrice globală 2x4, vector global 4x1
Procesul 0: încep înmulțirea matrice-vector
Procesul 0: matrice locală A - dimensiuni (2, 4)
Procesul 0: vector local x - dimensiuni (2,)
Procesul 0: pregătesc vectorul global xg - dimensiuni (4,)
Procesul 0: încep Allgather pentru a colecta vectorul complet
Procesul 0: Allgather completat, calculez înmulțirea locală
Procesul 0: înmulțirea completată, rezultat local - dimensiuni (2,)
Procesul 0: rezultat final - primul element: 1.633
Procesul 1: testez înmulțirea matrice-vector paralelă
Procesul 1: matrice globală 2x4, vector global 4x1
Procesul 1: încep înmulțirea matrice-vector
Procesul 1: matrice locală A - dimensiuni (2, 4)
Procesul 1: vector local x - dimensiuni (2,)
Procesul 1: pregătesc vectorul global xg - dimensiuni (4,)
Procesul 1: încep Allgather pentru a colecta vectorul complet
Procesul 1: Allgather completat, calculez înmulțirea locală
Procesul 1: înmulțirea completată, rezultat local - dimensiuni (2,)
Procesul 1: rezultat final - primul element: 1.323
```

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/cc
$ mpiexec -n 4 python3 parallel_mv.py 
Procesul 0: testez înmulțirea matrice-vector paralelă
Procesul 0: matrice globală 2x8, vector global 8x1
Procesul 0: încep înmulțirea matrice-vector
Procesul 0: matrice locală A - dimensiuni (2, 8)
Procesul 0: vector local x - dimensiuni (2,)
Procesul 0: pregătesc vectorul global xg - dimensiuni (8,)
Procesul 0: încep Allgather pentru a colecta vectorul complet
Procesul 0: Allgather completat, calculez înmulțirea locală
Procesul 0: înmulțirea completată, rezultat local - dimensiuni (2,)
Procesul 0: rezultat final - primul element: 3.165
Procesul 1: testez înmulțirea matrice-vector paralelă
Procesul 1: matrice globală 2x8, vector global 8x1
Procesul 1: încep înmulțirea matrice-vector
Procesul 1: matrice locală A - dimensiuni (2, 8)
Procesul 1: vector local x - dimensiuni (2,)
Procesul 1: pregătesc vectorul global xg - dimensiuni (8,)
Procesul 1: încep Allgather pentru a colecta vectorul complet
Procesul 1: Allgather completat, calculez înmulțirea locală
Procesul 1: înmulțirea completată, rezultat local - dimensiuni (2,)
Procesul 1: rezultat final - primul element: 3.085
Procesul 2: testez înmulțirea matrice-vector paralelă
Procesul 2: matrice globală 2x8, vector global 8x1
Procesul 2: încep înmulțirea matrice-vector
Procesul 2: matrice locală A - dimensiuni (2, 8)
Procesul 2: vector local x - dimensiuni (2,)
Procesul 2: pregătesc vectorul global xg - dimensiuni (8,)
Procesul 2: încep Allgather pentru a colecta vectorul complet
Procesul 2: Allgather completat, calculez înmulțirea locală
Procesul 2: înmulțirea completată, rezultat local - dimensiuni (2,)
Procesul 2: rezultat final - primul element: 3.522
Procesul 3: testez înmulțirea matrice-vector paralelă
Procesul 3: matrice globală 2x8, vector global 8x1
Procesul 3: încep înmulțirea matrice-vector
Procesul 3: matrice locală A - dimensiuni (2, 8)
Procesul 3: vector local x - dimensiuni (2,)
Procesul 3: pregătesc vectorul global xg - dimensiuni (8,)
Procesul 3: încep Allgather pentru a colecta vectorul complet
Procesul 3: Allgather completat, calculez înmulțirea locală
Procesul 3: înmulțirea completată, rezultat local - dimensiuni (2,)
Procesul 3: rezultat final - primul element: 2.426
```

### I/O 

**collective.py** - Demonstrează scrierea colectivă în fișier folosind `Write_at_all()` pentru I/O paralel eficient.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/io
$ mpiexec -n 4 python3 collective.py 
Procesul 0: deschid fișierul pentru scriere colectivă
Procesul 0: pregătesc buffer cu valoarea 0
Procesul 0: calculez offset-ul: 0 bytes
Procesul 0: încep scrierea colectivă la offset 0
Procesul 0: scrierea colectivă completată
Procesul 0: fișierul închis
Procesul 1: deschid fișierul pentru scriere colectivă
Procesul 1: pregătesc buffer cu valoarea 1
Procesul 1: calculez offset-ul: 40 bytes
Procesul 1: încep scrierea colectivă la offset 40
Procesul 1: scrierea colectivă completată
Procesul 1: fișierul închis
Procesul 2: deschid fișierul pentru scriere colectivă
Procesul 2: pregătesc buffer cu valoarea 2
Procesul 2: calculez offset-ul: 80 bytes
Procesul 2: încep scrierea colectivă la offset 80
Procesul 2: scrierea colectivă completată
Procesul 2: fișierul închis
Procesul 3: deschid fișierul pentru scriere colectivă
Procesul 3: pregătesc buffer cu valoarea 3
Procesul 3: calculez offset-ul: 120 bytes
Procesul 3: încep scrierea colectivă la offset 120
Procesul 3: scrierea colectivă completată
Procesul 3: fișierul închis
```

**non_continguous_collective.py** - Demonstrează scrierea non-contiguă folosind `Create_vector()` și `Set_view()` pentru layout-uri complexe de date în fișiere.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/io
$ mpiexec -n 4 python3 non_continguous_collective.py 
Procesul 0: încep scrierea non-contiguă în fișier
Procesul 0: fișierul deschis pentru scriere non-contiguă
Procesul 0: pregătesc buffer cu 10 elemente de valoare 0
Procesul 0: creez tipul de fișier vectorial
Procesul 0: tipul de fișier creat și commit-at
Procesul 0: calculez displacement-ul: 0 bytes
Procesul 0: view-ul setat cu displacement 0
Procesul 0: încep scrierea non-contiguă
Procesul 0: scrierea non-contiguă completată
Procesul 0: tipul de fișier eliberat și fișierul închis
Procesul 1: încep scrierea non-contiguă în fișier
Procesul 1: fișierul deschis pentru scriere non-contiguă
Procesul 1: pregătesc buffer cu 10 elemente de valoare 1
Procesul 1: creez tipul de fișier vectorial
Procesul 1: tipul de fișier creat și commit-at
Procesul 1: calculez displacement-ul: 4 bytes
Procesul 1: view-ul setat cu displacement 4
Procesul 1: încep scrierea non-contiguă
Procesul 1: scrierea non-contiguă completată
Procesul 1: tipul de fișier eliberat și fișierul închis
Procesul 2: încep scrierea non-contiguă în fișier
Procesul 2: fișierul deschis pentru scriere non-contiguă
Procesul 2: pregătesc buffer cu 10 elemente de valoare 2
Procesul 2: creez tipul de fișier vectorial
Procesul 2: tipul de fișier creat și commit-at
Procesul 2: calculez displacement-ul: 8 bytes
Procesul 2: view-ul setat cu displacement 8
Procesul 2: încep scrierea non-contiguă
Procesul 2: scrierea non-contiguă completată
Procesul 2: tipul de fișier eliberat și fișierul închis
Procesul 3: încep scrierea non-contiguă în fișier
Procesul 3: fișierul deschis pentru scriere non-contiguă
Procesul 3: pregătesc buffer cu 10 elemente de valoare 3
Procesul 3: creez tipul de fișier vectorial
Procesul 3: tipul de fișier creat și commit-at
Procesul 3: calculez displacement-ul: 12 bytes
Procesul 3: view-ul setat cu displacement 12
Procesul 3: încep scrierea non-contiguă
Procesul 3: scrierea non-contiguă completată
Procesul 3: tipul de fișier eliberat și fișierul închis
```

### GPU Computing

**gpu.py** - Aparent nu pot folosi CUPY, deoarece Apple nu mai suporta CUDA...

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1/tutorial/gpu
$ pip install cupy
Collecting cupy
  Downloading cupy-13.6.0.tar.gz (3.3 MB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 3.3/3.3 MB 25.5 MB/s  0:00:00
  Installing build dependencies ... done
  Getting requirements to build wheel ... error
  error: subprocess-exited-with-error
  
  × Getting requirements to build wheel did not run successfully.
  │ exit code: 1
  ╰─> [1 lines of output]
      Error: macOS is no longer supported
      [end of output]
  
  note: This error originates from a subprocess, and is likely not a problem with pip.
error: subprocess-exited-with-error

× Getting requirements to build wheel did not run successfully.
│ exit code: 1
╰─> See above for output.

note: This error originates from a subprocess, and is likely not a problem with pip.
```

## Distribuția Matricei

**matrix_distribution.py** - Demonstrează distribuția eficientă a unei matrice n×n pe procese folosind trei metode: pe linii, pe coloane și pe blocuri. Scriptul folosește comunicarea point-to-point (`send()`/`recv()`) pentru distribuirea părților matricei de la procesul master către toate celelalte procese.

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1
$ mpiexec -n 2 python3 matrix_distribution.py
Procesul 0: matrice 2x2, 2 procese
Procesul 0: matrice generată:
[[9 5]
 [3 9]]

=== DISTRIBUȚIA PE LINII ===
Procesul 0: am trimis linii către toate procesele
Procesul 0: am primit 1 linii
Procesul 0: linii locale:
[[9 5]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 0: am trimis coloane către toate procesele
Procesul 0: am primit 1 coloane
Procesul 0: coloane locale:
[[9]
 [3]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 0: am trimis 2 blocuri
Procesul 0: am primit blocul de dimensiuni (1, 2)
Procesul 0: blocul local:
[[9 5]]
Procesul 1: matrice 2x2, 2 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 1: am primit 1 linii
Procesul 1: linii locale:
[[3 9]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 1: am primit 1 coloane
Procesul 1: coloane locale:
[[5]
 [9]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 1: am primit blocul de dimensiuni (1, 2)
Procesul 1: blocul local:
[[3 9]]

iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1
$ mpiexec -n 4 python3 matrix_distribution.py
Procesul 0: matrice 4x4, 4 procese
Procesul 0: matrice generată:
[[7 9 4 9]
 [5 7 3 9]
 [1 7 3 3]
 [5 6 7 2]]

=== DISTRIBUȚIA PE LINII ===
Procesul 0: am trimis linii către toate procesele
Procesul 0: am primit 1 linii
Procesul 0: linii locale:
[[7 9 4 9]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 0: am trimis coloane către toate procesele
Procesul 0: am primit 1 coloane
Procesul 0: coloane locale:
[[7]
 [5]
 [1]
 [5]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 0: am trimis 4 blocuri
Procesul 0: am primit blocul de dimensiuni (1, 4)
Procesul 0: blocul local:
[[7 9 4 9]]
Procesul 1: matrice 4x4, 4 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 1: am primit 1 linii
Procesul 1: linii locale:
[[5 7 3 9]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 1: am primit 1 coloane
Procesul 1: coloane locale:
[[9]
 [7]
 [7]
 [6]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 1: am primit blocul de dimensiuni (1, 4)
Procesul 1: blocul local:
[[5 7 3 9]]
Procesul 3: matrice 4x4, 4 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 3: am primit 1 linii
Procesul 3: linii locale:
[[5 6 7 2]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 3: am primit 1 coloane
Procesul 3: coloane locale:
[[9]
 [9]
 [3]
 [2]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 3: am primit blocul de dimensiuni (1, 4)
Procesul 3: blocul local:
[[5 6 7 2]]
Procesul 2: matrice 4x4, 4 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 2: am primit 1 linii
Procesul 2: linii locale:
[[1 7 3 3]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 2: am primit 1 coloane
Procesul 2: coloane locale:
[[4]
 [3]
 [3]
 [7]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 2: am primit blocul de dimensiuni (1, 4)
Procesul 2: blocul local:
[[1 7 3 3]]

iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 1
$ mpiexec -n 8 python3 matrix_distribution.py
Procesul 0: matrice 8x8, 8 procese
Procesul 0: matrice generată:
[[7 9 2 6 1 4 6 3]
 [2 2 4 1 5 6 8 2]
 [6 3 6 5 9 4 6 3]
 [9 4 1 6 6 4 9 5]
 [5 6 1 9 2 6 7 3]
 [5 2 8 1 5 7 6 6]
 [6 7 7 2 1 8 7 9]
 [3 8 2 1 7 3 4 9]]

=== DISTRIBUȚIA PE LINII ===
Procesul 0: am trimis linii către toate procesele
Procesul 0: am primit 1 linii
Procesul 0: linii locale:
[[7 9 2 6 1 4 6 3]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 0: am trimis coloane către toate procesele
Procesul 0: am primit 1 coloane
Procesul 0: coloane locale:
[[7]
 [2]
 [6]
 [9]
 [5]
 [5]
 [6]
 [3]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 0: am trimis 8 blocuri
Procesul 0: am primit blocul de dimensiuni (1, 8)
Procesul 0: blocul local:
[[7 9 2 6 1 4 6 3]]
Procesul 3: matrice 8x8, 8 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 3: am primit 1 linii
Procesul 3: linii locale:
[[9 4 1 6 6 4 9 5]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 3: am primit 1 coloane
Procesul 3: coloane locale:
[[6]
 [1]
 [5]
 [6]
 [9]
 [1]
 [2]
 [1]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 3: am primit blocul de dimensiuni (1, 8)
Procesul 3: blocul local:
[[9 4 1 6 6 4 9 5]]
Procesul 4: matrice 8x8, 8 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 4: am primit 1 linii
Procesul 4: linii locale:
[[5 6 1 9 2 6 7 3]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 4: am primit 1 coloane
Procesul 4: coloane locale:
[[1]
 [5]
 [9]
 [6]
 [2]
 [5]
 [1]
 [7]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 4: am primit blocul de dimensiuni (1, 8)
Procesul 4: blocul local:
[[5 6 1 9 2 6 7 3]]
Procesul 1: matrice 8x8, 8 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 1: am primit 1 linii
Procesul 1: linii locale:
[[2 2 4 1 5 6 8 2]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 1: am primit 1 coloane
Procesul 1: coloane locale:
[[9]
 [2]
 [3]
 [4]
 [6]
 [2]
 [7]
 [8]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 1: am primit blocul de dimensiuni (1, 8)
Procesul 1: blocul local:
[[2 2 4 1 5 6 8 2]]
Procesul 5: matrice 8x8, 8 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 5: am primit 1 linii
Procesul 5: linii locale:
[[5 2 8 1 5 7 6 6]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 5: am primit 1 coloane
Procesul 5: coloane locale:
[[4]
 [6]
 [4]
 [4]
 [6]
 [7]
 [8]
 [3]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 5: am primit blocul de dimensiuni (1, 8)
Procesul 5: blocul local:
[[5 2 8 1 5 7 6 6]]
Procesul 6: matrice 8x8, 8 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 6: am primit 1 linii
Procesul 6: linii locale:
[[6 7 7 2 1 8 7 9]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 6: am primit 1 coloane
Procesul 6: coloane locale:
[[6]
 [8]
 [6]
 [9]
 [7]
 [6]
 [7]
 [4]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 6: am primit blocul de dimensiuni (1, 8)
Procesul 6: blocul local:
[[6 7 7 2 1 8 7 9]]
Procesul 7: matrice 8x8, 8 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 7: am primit 1 linii
Procesul 7: linii locale:
[[3 8 2 1 7 3 4 9]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 7: am primit 1 coloane
Procesul 7: coloane locale:
[[3]
 [2]
 [3]
 [5]
 [3]
 [6]
 [9]
 [9]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 7: am primit blocul de dimensiuni (1, 8)
Procesul 7: blocul local:
[[3 8 2 1 7 3 4 9]]
Procesul 2: matrice 8x8, 8 procese

=== DISTRIBUȚIA PE LINII ===
Procesul 2: am primit 1 linii
Procesul 2: linii locale:
[[6 3 6 5 9 4 6 3]]

=== DISTRIBUȚIA PE COLOANE ===
Procesul 2: am primit 1 coloane
Procesul 2: coloane locale:
[[2]
 [4]
 [6]
 [1]
 [1]
 [8]
 [7]
 [2]]

=== DISTRIBUȚIA PE BLOCURI ===
Procesul 2: am primit blocul de dimensiuni (1, 8)
Procesul 2: blocul local:
[[6 3 6 5 9 4 6 3]]
```

Scriptul demonstrează trei strategii de distribuție:
- **Pe linii**: Fiecare proces primește linii consecutive din matrice
- **Pe coloane**: Fiecare proces primește coloane consecutive din matrice  
- **Pe blocuri**: Matricea se împarte în sub-matrici dreptunghiulare

---