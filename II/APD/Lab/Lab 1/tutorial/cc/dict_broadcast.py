from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

if rank == 0:
    data = {'key1' : [7, 2.72, 2+3j],
            'key2' : ( 'abc', 'xyz')}
    print(f"Procesul {rank}: pregătesc datele pentru broadcast: {data}")
else:
    data = None
    print(f"Procesul {rank}: aștept să primesc date prin broadcast")

print(f"Procesul {rank}: încep broadcast")
data = comm.bcast(data, root=0)
print(f"Procesul {rank}: am primit datele prin broadcast: {data}")