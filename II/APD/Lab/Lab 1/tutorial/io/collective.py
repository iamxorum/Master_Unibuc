from mpi4py import MPI
import numpy as np

amode = MPI.MODE_WRONLY|MPI.MODE_CREATE
comm = MPI.COMM_WORLD
rank = comm.Get_rank()

print(f"Procesul {rank}: deschid fișierul pentru scriere colectivă")
fh = MPI.File.Open(comm, "./datafile.contig", amode)

buffer = np.empty(10, dtype=np.int32)
buffer[:] = comm.Get_rank()
print(f"Procesul {rank}: pregătesc buffer cu valoarea {comm.Get_rank()}")

offset = comm.Get_rank()*buffer.nbytes
print(f"Procesul {rank}: calculez offset-ul: {offset} bytes")

print(f"Procesul {rank}: încep scrierea colectivă la offset {offset}")
fh.Write_at_all(offset, buffer)
print(f"Procesul {rank}: scrierea colectivă completată")

fh.Close()
print(f"Procesul {rank}: fișierul închis")