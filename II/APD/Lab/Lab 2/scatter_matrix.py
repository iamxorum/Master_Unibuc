#!/usr/bin/env python3

from mpi4py import MPI
import numpy as np

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    def safe_print(*args, **kwargs):
        print(*args, **kwargs, flush=True)
    
    safe_print(f"Procesul {rank}: inițializat, total {size} procese")
    
    # Root generează matricea p × p
    if rank == 0:
        p = size  # număr de procesoare = dimensiune matrice
        matrix = np.random.rand(p, p)
        safe_print(f"\nProcesul {rank}: am generat matricea {p}x{p}")
        safe_print(f"Procesul {rank}: matrice =\n{matrix}")
        safe_print(f"\nProcesul {rank}: încep distribuția liniilor și coloanelor")
    else:
        matrix = None
        my_line = np.empty(size, dtype='f')
        my_column = np.empty(size, dtype='f')
    
    safe_print(f"\n=== Distribuție linii ===")
    
    if rank == 0:
        my_line = np.array(matrix[0, :], dtype='f', copy=True)  # Make contiguous
        safe_print(f"Procesul {rank}: îmi pastrez linia {rank} = {my_line}")
        for i in range(1, size):
            line_data = np.array(matrix[i, :], dtype='f', copy=True)  # Make contiguous
            safe_print(f"Procesul {rank}: trimit linia {i} procesului {i}")
            comm.Send([line_data, MPI.FLOAT], dest=i, tag=0)
    else:
        comm.Recv([my_line, MPI.FLOAT], source=0, tag=0)
        safe_print(f"Procesul {rank}: am primit linia {rank} = {my_line}")
    
    safe_print(f"\n=== Distribuție coloane ===")
    
    if rank == 0:
        my_column = np.array(matrix[:, 0], dtype='f', copy=True)  # Make copy for contiguous
        safe_print(f"Procesul {rank}: îmi pastrez coloana {rank} = {my_column}")
        for i in range(1, size):
            column_data = np.array(matrix[:, i], dtype='f', copy=True)  # Make contiguous
            safe_print(f"Procesul {rank}: trimit coloana {i} procesului {i}")
            comm.Send([column_data, MPI.FLOAT], dest=i, tag=1)
    else:
        comm.Recv([my_column, MPI.FLOAT], source=0, tag=1)
        safe_print(f"Procesul {rank}: am primit coloana {rank} = {my_column}")
    
    comm.Barrier()
    
    safe_print(f"\n=== Verificare pentru procesul {rank} ===")
    safe_print(f"Procesul {rank}: Linia[{rank}] = {my_line}")
    safe_print(f"Procesul {rank}: Coloana[{rank}] = {my_column}")
    
    comm.Barrier()
    safe_print(f"\nProcesul {rank}: finalizat!")

if __name__ == "__main__":
    main()

