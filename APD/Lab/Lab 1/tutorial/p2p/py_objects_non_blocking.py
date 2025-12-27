from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

if rank == 0:
    data = {'a': 7, 'b': 3.14}
    print(f"Procesul {rank}: încep trimiterea non-blocking a datelor {data}")
    req = comm.isend(data, dest=1, tag=11)
    print(f"Procesul {rank}: aștept finalizarea trimiterii")
    req.wait()
    print(f"Procesul {rank}: trimiterea s-a finalizat")
elif rank == 1:
    print(f"Procesul {rank}: încep primirea non-blocking")
    req = comm.irecv(source=0, tag=11)
    print(f"Procesul {rank}: aștept finalizarea primirii")
    data = req.wait()
    print(f"Procesul {rank}: am primit datele {data}")