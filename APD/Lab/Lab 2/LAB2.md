# Lab 2 - Algoritmi Paraleli și Distribuiți

## [2p] Barrier

Am implementat un program paralel care demonstrează sincronizarea proceselor folosind bariere MPI. Programul `barrier_demo.py` respectă cerințele:
- Procesul root simulează o activitate dormind 4 secunde
- Celelalte procese așteaptă root cu o barieră
- Procesele slave se pregătesc de lucru (sleep)
- Toate procesele simulează activitate aleatoare între 0 și 10 secunde
- Al doilea barrier sincronizează toate procesele
- Root confirmă finalizarea tuturor proceselor

Am testat programul și iată outputul:

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 2
$ mpiexec -n 4 python3 barrier_demo.py
Procesul 1: inițializat, total 4 procese
Procesul 1: aștept la prima barieră...
Procesul 2: inițializat, total 4 procese
Procesul 2: aștept la prima barieră...
Procesul 0: inițializat, total 4 procese

=== Procesul ROOT (0) începe activitatea ===
Procesul 0: simulez activitate (dorm 4 secunde)...
Procesul 3: inițializat, total 4 procese
Procesul 3: aștept la prima barieră...
Procesul 0: Activitatea root a fost finalizată!
Procesul 0: aștept la prima barieră...
Procesul 0: simulez activitate aleatoare (0.63 secunde)...
Procesul 1: Mă pregătesc de lucru (și de sleep)...
Procesul 1: simulez activitate aleatoare (3.12 secunde)...
Procesul 2: Mă pregătesc de lucru (și de sleep)...
Procesul 3: Mă pregătesc de lucru (și de sleep)...
Procesul 2: simulez activitate aleatoare (8.01 secunde)...
Procesul 3: simulez activitate aleatoare (9.05 secunde)...
Procesul 0: Activitatea aleatoare finalizată!
Procesul 0: aștept la a doua barieră pentru sincronizare...
Procesul 1: Activitatea aleatoare finalizată!
Procesul 1: aștept la a doua barieră pentru sincronizare...
Procesul 2: Activitatea aleatoare finalizată!
Procesul 2: aștept la a doua barieră pentru sincronizare...
Procesul 3: Activitatea aleatoare finalizată!
Procesul 3: aștept la a doua barieră pentru sincronizare...

=== Procesul ROOT (0) confirmă ===
✅ TOATE PROCESELE au terminat activitatea cu succes!
Total procese participante: 4
```

### Observații

1. **Prima barieră**: Toate procesele slave (1, 2, 3) așteaptă la barieră în timp ce root simulează activitatea de 4 secunde.

2. **Distribuția activității aleatoare**: Procesele rulează activități de durate diferite (0.63s, 3.12s, 8.01s, 9.05s), simulând execuții asincrone.

3. **A doua barieră**: Toate procesele se sincronizează după ce termină activitatea, indiferent de durată.

4. **Confirmare finală**: Root primește confirmare că toate procesele au trecut prin a doua barieră.

**Notă**: Am folosit `flush=True` în print pentru a evita bufferizarea în MPI și a păstra ordinea cronologică a mesajelor.

## [1p] Broadcast

Am implementat un program care demonstrează folosirea rutinei de broadcast în MPI. Programul `broadcast_demo.py` trimite:
- **Dicționar**: Procesul root trimite un dicționar cu două chei ('key1': [3, 24.62, 9+4j], 'key2': ('fmi', 'unibuc')) către toate procesele
- **Vector NumPy**: Procesul root trimite un vector folosind `Bcast()` pentru eficiență

Am testat programul cu 4 procese și iată ce s-a întâmplat:

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 2
$ mpiexec -n 4 python3 broadcast_demo.py
Procesul 0: inițializat, total 4 procese

=== PARTEA 1: Broadcast Dicționar ===
Procesul 0: pregătesc dicționarul pentru broadcast
Procesul 0: dicționar = {'key1': [3, 24.62, (9+4j)], 'key2': ('fmi', 'unibuc')}
Procesul 0: încep broadcast dicționar
Procesul 1: inițializat, total 4 procese

=== PARTEA 1: Broadcast Dicționar ===
Procesul 1: aștept să primesc dicționarul
Procesul 1: încep broadcast dicționar
Procesul 2: inițializat, total 4 procese

=== PARTEA 1: Broadcast Dicționar ===
Procesul 2: aștept să primesc dicționarul
Procesul 2: încep broadcast dicționar
Procesul 3: inițializat, total 4 procese

=== PARTEA 1: Broadcast Dicționar ===
Procesul 3: aștept să primesc dicționarul
Procesul 3: încep broadcast dicționar
Procesul 0: am primit dicționarul prin broadcast
Procesul 0: key1 = [3, 24.62, (9+4j)]
Procesul 0: key2 = ('fmi', 'unibuc')
Procesul 1: am primit dicționarul prin broadcast
Procesul 1: key1 = [3, 24.62, (9+4j)]
Procesul 1: key2 = ('fmi', 'unibuc')

=== PARTEA 2: Broadcast Vector NumPy ===
Procesul 1: aștept să primesc vectorul
Procesul 2: am primit dicționarul prin broadcast
Procesul 2: key1 = [3, 24.62, (9+4j)]
Procesul 2: key2 = ('fmi', 'unibuc')

=== PARTEA 2: Broadcast Vector NumPy ===
Procesul 2: aștept să primesc vectorul
Procesul 2: încep broadcast vector
Procesul 3: am primit dicționarul prin broadcast
Procesul 3: key1 = [3, 24.62, (9+4j)]
Procesul 3: key2 = ('fmi', 'unibuc')

=== PARTEA 2: Broadcast Vector NumPy ===
Procesul 3: aștept să primesc vectorul
Procesul 3: încep broadcast vector

=== PARTEA 2: Broadcast Vector NumPy ===
Procesul 0: pregătesc vectorul pentru broadcast
Procesul 1: încep broadcast vector
Procesul 0: vector = [ 1  2  3  4  5 10 15 20 25 30]
Procesul 0: încep broadcast vector
Procesul 0: am primit vectorul prin broadcast
Procesul 1: am primit vectorul prin broadcast
Procesul 2: am primit vectorul prin broadcast
Procesul 3: am primit vectorul prin broadcast
Procesul 0: vector primit = [ 1  2  3  4  5 10 15 20 25 30]

Procesul 0: completat cu succes!
Procesul 1: vector primit = [ 1  2  3  4  5 10 15 20 25 30]

Procesul 1: completat cu succes!
Procesul 2: vector primit = [ 1  2  3  4  5 10 15 20 25 30]

Procesul 2: completat cu succes!
Procesul 3: vector primit = [ 1  2  3  4  5 10 15 20 25 30]

Procesul 3: completat cu succes!
```

### Observații personale

Am observat următoarele lucruri importante:
- Pentru dicționar am folosit `bcast()` care funcționează bine cu obiecte Python complexe
- Pentru vector am folosit `Bcast()` cu tipuri MPI explicite pentru mai multă eficiență
- Toate procesele au primit exact aceleași date de la root, fără erori

## [2p] Scatter

Am implementat un program care demonstrează distribuția unei matrice p×p folosind scatter. Programul `scatter_matrix.py`:

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 2
$ mpiexec -n 4 python3 scatter_matrix.py
Procesul 0: inițializat, total 4 procese
Procesul 1: inițializat, total 4 procese

=== Distribuție linii ===
Procesul 2: inițializat, total 4 procese

=== Distribuție linii ===
Procesul 3: inițializat, total 4 procese

=== Distribuție linii ===

Procesul 0: am generat matricea 4x4
Procesul 0: matrice =
[[0.36321953 0.95708633 0.79316035 0.57353625]
 [0.53893366 0.90876075 0.12175245 0.66413512]
 [0.10799837 0.70217957 0.43826757 0.06013094]
 [0.31810286 0.62437312 0.18559398 0.61953216]]

Procesul 0: încep distribuția liniilor și coloanelor

=== Distribuție linii ===
Procesul 0: îmi pastrez linia 0 = [0.36321953 0.9570863  0.7931604  0.5735363 ]
Procesul 0: trimit linia 1 procesului 1
Procesul 0: trimit linia 2 procesului 2
Procesul 0: trimit linia 3 procesului 3

=== Distribuție coloane ===
Procesul 0: îmi pastrez coloana 0 = [0.36321953 0.53893363 0.10799837 0.31810287]
Procesul 0: trimit coloana 1 procesului 1
Procesul 0: trimit coloana 2 procesului 2
Procesul 0: trimit coloana 3 procesului 3
Procesul 1: am primit linia 1 = [0.53893363 0.9087607  0.12175245 0.6641351 ]

=== Distribuție coloane ===
Procesul 3: am primit linia 3 = [0.31810287 0.62437314 0.18559398 0.61953217]

=== Distribuție coloane ===
Procesul 2: am primit linia 2 = [0.10799837 0.70217955 0.43826756 0.06013094]

=== Distribuție coloane ===
Procesul 1: am primit coloana 1 = [0.9570863  0.9087607  0.70217955 0.62437314]
Procesul 3: am primit coloana 3 = [0.5735363  0.6641351  0.06013094 0.61953217]
Procesul 2: am primit coloana 2 = [0.7931604  0.12175245 0.43826756 0.18559398]

=== Verificare pentru procesul 0 ===

=== Verificare pentru procesul 2 ===

=== Verificare pentru procesul 1 ===

=== Verificare pentru procesul 3 ===
Procesul 0: Linia[0] = [0.36321953 0.9570863  0.7931604  0.5735363 ]
Procesul 1: Linia[1] = [0.53893363 0.9087607  0.12175245 0.6641351 ]
Procesul 2: Linia[2] = [0.10799837 0.70217955 0.43826756 0.06013094]
Procesul 3: Linia[3] = [0.31810287 0.62437314 0.18559398 0.61953217]
Procesul 0: Coloana[0] = [0.36321953 0.53893363 0.10799837 0.31810287]
Procesul 1: Coloana[1] = [0.9570863  0.9087607  0.70217955 0.62437314]
Procesul 3: Coloana[3] = [0.5735363  0.6641351  0.06013094 0.61953217]
Procesul 2: Coloana[2] = [0.7931604  0.12175245 0.43826756 0.18559398]

Procesul 0: finalizat!

Procesul 2: finalizat!

Procesul 1: finalizat!

Procesul 3: finalizat!
```

- Procesul root generează o matrice p×p (p = număr de procesoare)
- Root trimite fiecărui proces cu indexul `rank` linia cu indexul `rank` și coloana cu indexul `rank`
- Folosesc `Send()` și `Recv()` pentru distribuția personalizată
- Afișez datele primite pentru verificare

## [5p] Înmulțire Matrice-Vector pe Inel

Am implementat o înmulțire eficientă matrice-vector pe topologia de inel cu programul `matrix_vector_ring.py`.

### Cum funcționează:

1. **Distribuție echilibrată**: Root generează matricea A (n×n) și vectorul x (n elemente). Fiecare nod i primește:
   - Coloana i din A
   - Componenta i din x

2. **Calcul parțial**: Fiecare nod calculează produsul său: `coloana[i] * x[i]`

3. **Difuzare pe inel**: Folosesc `Allreduce` cu operația `SUM` pentru a acumula toate produsele parțiale

4. **Rezultat final**: Toate nodurile primesc rezultatul complet SUM(A × x)

```bash
iamxorum@xrm-mac-pro:~/Desktop/UniBuc/Algoritmi Paraleli si Distribuiti/Lab/Lab 2
$ mpiexec -n 4 python3 matrix_vector_ring.py
Procesul 1: inițializat pe inel, total 4 noduri
Procesul 2: inițializat pe inel, total 4 noduri
Procesul 3: inițializat pe inel, total 4 noduri
Procesul 0: inițializat pe inel, total 4 noduri

Procesul 0: matricea A 4x4
A =
[[4 7 7 5]
 [8 5 7 6]
 [3 5 4 7]
 [7 4 4 8]]
Procesul 0: vectorul x = [4 5 2 6]
Procesul 0: încep distribuția echilibrată pe blocuri

Procesul 0: am coloana[0] = [4 8 3 7]
Procesul 0: am componenta x[0] = 4
Procesul 0: am trimis coloana[1] și x[1] către nodul 1
Procesul 0: am trimis coloana[2] și x[2] către nodul 2
Procesul 0: am trimis coloana[3] și x[3] către nodul 3
Procesul 2: am primit coloana[2] = [7 7 4 4]
Procesul 2: am primit x[2] = 2
Procesul 3: am primit coloana[3] = [5 6 7 8]
Procesul 3: am primit x[3] = 6
Procesul 1: am primit coloana[1] = [7 5 5 4]
Procesul 1: am primit x[1] = 5

=== Înmulțire matrice-vector pe inel ===

=== Înmulțire matrice-vector pe inel ===

=== Înmulțire matrice-vector pe inel ===

=== Înmulțire matrice-vector pe inel ===
Procesul 0: rezultat parțial = coloana[0] * x[0] = [16 32 12 28]
Procesul 2: rezultat parțial = coloana[2] * x[2] = [14 14  8  8]
Procesul 3: rezultat parțial = coloana[3] * x[3] = [30 36 42 48]
Procesul 1: rezultat parțial = coloana[1] * x[1] = [35 25 25 20]
Procesul 0: rezultat final (toate sumele) = [ 95 107  87 104]
Procesul 2: rezultat final (toate sumele) = [ 95 107  87 104]
Procesul 3: rezultat final (toate sumele) = [ 95 107  87 104]
Procesul 1: rezultat final (toate sumele) = [ 95 107  87 104]

Procesul 1: Înmulțirea pe inel completată!
Procesul 1: Suma totală = 393

Procesul 0: Înmulțirea pe inel completată!
Procesul 0: Suma totală = 393

Procesul 2: Înmulțirea pe inel completată!
Procesul 2: Suma totală = 393

Procesul 3: Înmulțirea pe inel completată!
Procesul 3: Suma totală = 393
```
