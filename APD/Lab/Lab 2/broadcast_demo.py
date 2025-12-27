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
    
    # pas 1 - broadcast dictionar
    safe_print(f"\n=== PARTEA 1: Broadcast Dicționar ===")
    
    if rank == 0:
        data_dict = {
            'key1': [3, 24.62, 9+4j],
            'key2': ('fmi', 'unibuc')
        }
        safe_print(f"Procesul {rank}: pregătesc dicționarul pentru broadcast")
        safe_print(f"Procesul {rank}: dicționar = {data_dict}")
    else:
        data_dict = None
        safe_print(f"Procesul {rank}: aștept să primesc dicționarul")
    
    safe_print(f"Procesul {rank}: încep broadcast dicționar")
    data_dict = comm.bcast(data_dict, root=0)
    safe_print(f"Procesul {rank}: am primit dicționarul prin broadcast")
    safe_print(f"Procesul {rank}: key1 = {data_dict['key1']}")
    safe_print(f"Procesul {rank}: key2 = {data_dict['key2']}")
    
    # pas 2 - broadcast vector
    safe_print(f"\n=== PARTEA 2: Broadcast Vector NumPy ===")
    
    if rank == 0:
        data_vector = np.array([1, 2, 3, 4, 5, 10, 15, 20, 25, 30], dtype='i')
        safe_print(f"Procesul {rank}: pregătesc vectorul pentru broadcast")
        safe_print(f"Procesul {rank}: vector = {data_vector}")
    else:
        # Vector gol pentru primire
        data_vector = np.empty(10, dtype='i')
        safe_print(f"Procesul {rank}: aștept să primesc vectorul")
    
    safe_print(f"Procesul {rank}: încep broadcast vector")
    comm.Bcast([data_vector, MPI.INT], root=0)
    safe_print(f"Procesul {rank}: am primit vectorul prin broadcast")
    safe_print(f"Procesul {rank}: vector primit = {data_vector}")
    
    safe_print(f"\nProcesul {rank}: completat cu succes!")

if __name__ == "__main__":
    main()

