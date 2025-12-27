from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

if rank == 0:
    data = np.arange(100, dtype='i')
    print(f"Procesul {rank}: pregătesc array numpy pentru broadcast: primul element {data[0]}, ultimul element {data[-1]}")
else:
    data = np.empty(100, dtype='i')
    print(f"Procesul {rank}: pregătesc array gol pentru primirea datelor prin broadcast")

print(f"Procesul {rank}: încep broadcast")
comm.Bcast(data, root=0)
print(f"Procesul {rank}: broadcast completat, verific array-ul")
for i in range(100):
    assert data[i] == i
print(f"Procesul {rank}: verificare reușită - toate elementele sunt corecte")