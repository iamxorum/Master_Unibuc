from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

sendbuf = None
if rank == 0:
    sendbuf = np.empty([size, 100], dtype='i')
    sendbuf.T[:,:] = range(size)
    print(f"Procesul {rank}: pregătesc matricea pentru scatter - dimensiuni {sendbuf.shape}")
    print(f"Procesul {rank}: primul rând: {sendbuf[0][:5]}...")
else:
    print(f"Procesul {rank}: nu sunt root, nu pregătesc matricea")

recvbuf = np.empty(100, dtype='i')
print(f"Procesul {rank}: încep scatter")
comm.Scatter(sendbuf, recvbuf, root=0)
print(f"Procesul {rank}: scatter completat, verific array-ul primit")
assert np.allclose(recvbuf, rank)
print(f"Procesul {rank}: verificare reușită - toate elementele sunt {rank}")