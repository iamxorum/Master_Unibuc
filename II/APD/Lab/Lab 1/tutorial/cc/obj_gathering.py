from mpi4py import MPI

comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

data = (rank+1)**2
print(f"Procesul {rank}: pregătesc datele pentru gather: {data}")
print(f"Procesul {rank}: încep gather")
data = comm.gather(data, root=0)
if rank == 0:
    print(f"Procesul {rank}: am primit toate datele prin gather: {data}")
    for i in range(size):
        assert data[i] == (i+1)**2
        print(f"Procesul {rank}: verificare reușită pentru procesul {i} - {data[i]} == {(i+1)**2}")
else:
    print(f"Procesul {rank}: gather completat, data este None")
    assert data is None