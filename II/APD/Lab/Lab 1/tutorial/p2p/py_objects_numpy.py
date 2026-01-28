from mpi4py import MPI
import numpy

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

# passing MPI datatypes explicitly
if rank == 0:
    data = numpy.arange(1000, dtype='i')
    print(f"Procesul {rank}: trimit array numpy cu tip explicit MPI.INT")
    comm.Send([data, MPI.INT], dest=1, tag=77)
    print(f"Procesul {rank}: array trimis cu succes")
elif rank == 1:
    data = numpy.empty(1000, dtype='i')
    print(f"Procesul {rank}: primesc array cu tip explicit MPI.INT")
    comm.Recv([data, MPI.INT], source=0, tag=77)
    print(f"Procesul {rank}: am primit array-ul, primul element: {data[0]}")

# automatic MPI datatype discovery
if rank == 0:
    data = numpy.arange(100, dtype=numpy.float64)
    print(f"Procesul {rank}: trimit array numpy cu auto-detectare tip")
    comm.Send(data, dest=1, tag=13)
    print(f"Procesul {rank}: array auto-detectat trimis")
elif rank == 1:
    data = numpy.empty(100, dtype=numpy.float64)
    print(f"Procesul {rank}: primesc array cu auto-detectare tip")
    comm.Recv(data, source=0, tag=13)
    print(f"Procesul {rank}: am primit array auto-detectat, primul element: {data[0]}")