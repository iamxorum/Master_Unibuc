from mpi4py import MPI

comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

if rank == 0:
    data = [(i+1)**2 for i in range(size)]
    print(f"Procesul {rank}: pregătesc datele pentru scatter: {data}")
else:
    data = None
    print(f"Procesul {rank}: aștept să primesc o parte din date prin scatter")

print(f"Procesul {rank}: încep scatter")
data = comm.scatter(data, root=0)
print(f"Procesul {rank}: am primit partea mea prin scatter: {data}")
assert data == (rank+1)**2
print(f"Procesul {rank}: verificare reușită - {data} == {(rank+1)**2}")