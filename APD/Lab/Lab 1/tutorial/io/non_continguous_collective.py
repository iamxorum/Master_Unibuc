from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

print(f"Procesul {rank}: încep scrierea non-contiguă în fișier")
amode = MPI.MODE_WRONLY|MPI.MODE_CREATE
fh = MPI.File.Open(comm, "./datafile.noncontig", amode)
print(f"Procesul {rank}: fișierul deschis pentru scriere non-contiguă")

item_count = 10
buffer = np.empty(item_count, dtype='i')
buffer[:] = rank
print(f"Procesul {rank}: pregătesc buffer cu {item_count} elemente de valoare {rank}")

print(f"Procesul {rank}: creez tipul de fișier vectorial")
filetype = MPI.INT.Create_vector(item_count, 1, size)
filetype.Commit()
print(f"Procesul {rank}: tipul de fișier creat și commit-at")

displacement = MPI.INT.Get_size()*rank
print(f"Procesul {rank}: calculez displacement-ul: {displacement} bytes")
fh.Set_view(displacement, filetype=filetype)
print(f"Procesul {rank}: view-ul setat cu displacement {displacement}")

print(f"Procesul {rank}: încep scrierea non-contiguă")
fh.Write_all(buffer)
print(f"Procesul {rank}: scrierea non-contiguă completată")

filetype.Free()
fh.Close()
print(f"Procesul {rank}: tipul de fișier eliberat și fișierul închis")