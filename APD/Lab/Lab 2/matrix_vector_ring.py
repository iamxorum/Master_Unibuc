#!/usr/bin/env python3

from mpi4py import MPI
import numpy as np

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    def safe_print(*args, **kwargs):
        print(*args, **kwargs, flush=True)
    
    safe_print(f"Procesul {rank}: inițializat pe inel, total {size} noduri")
    
    # Root generează A și x cu numere întregi
    if rank == 0:
        size = 4
        n = size  # dimensiune matrice A (n×n) și vector x
        A = np.random.randint(1, 10, (n, n))  # Numere întregi 1-9
        x = np.random.randint(1, 10, n)  # Numere întregi 1-9
        safe_print(f"\nProcesul {rank}: matricea A {n}x{n}")
        safe_print(f"A =\n{A}")
        safe_print(f"Procesul {rank}: vectorul x = {x}")
        safe_print(f"Procesul {rank}: încep distribuția echilibrată pe blocuri")
    else:
        A = None
        x = None
        n = None
    
    # broadcast dimensiunea
    n = comm.bcast(n, root=0)
    
    # distribuție echilibrată: nodul i primește coloana i și componenta i
    my_column_A = np.empty(n, dtype='i')  # Integer
    my_component_x = np.empty(1, dtype='i')  # Integer
    
    if rank == 0:
        # Root își păstrează coloana 0 și componenta 0
        my_column_A = np.array(A[:, 0], dtype='i', copy=True)
        my_component_x = np.array([x[0]], dtype='i')
        
        safe_print(f"\nProcesul {rank}: am coloana[0] = {my_column_A}")
        safe_print(f"Procesul {rank}: am componenta x[0] = {my_component_x[0]}")

        for i in range(1, size):
            column_data = np.array(A[:, i], dtype='i', copy=True)
            component_data = np.array([x[i]], dtype='i')
            
            # trimite coloana i catre nodul i
            comm.Send([column_data, MPI.INT], dest=i, tag=0)
            # trimite componenta x[i] catre nodul i
            comm.Send([component_data, MPI.INT], dest=i, tag=1)
            
            safe_print(f"Procesul {rank}: am trimis coloana[{i}] și x[{i}] către nodul {i}")
    else:
        # primeste coloana rank
        comm.Recv([my_column_A, MPI.INT], source=0, tag=0)
        # primeste componenta x[rank]
        comm.Recv([my_component_x, MPI.INT], source=0, tag=1)
        safe_print(f"Procesul {rank}: am primit coloana[{rank}] = {my_column_A}")
        safe_print(f"Procesul {rank}: am primit x[{rank}] = {my_component_x[0]}")
    
    comm.Barrier()
    
    safe_print(f"\n=== Înmulțire matrice-vector pe inel ===")
    
    # pas 1 - fiecare nod calculeaza produsul sau partial
    partial_result = my_column_A * my_component_x[0]
    safe_print(f"Procesul {rank}: rezultat parțial = coloana[{rank}] * x[{rank}] = {partial_result}")
    
    # pas 2 - difuzare pe inel folosind Allreduce
    result = np.zeros(n, dtype='i')
    comm.Allreduce([partial_result, MPI.INT], [result, MPI.INT], op=MPI.SUM)
    
    # pas 3 - fiecare nod are acum rezultatul complet
    safe_print(f"Procesul {rank}: rezultat final (toate sumele) = {result}")
    
    comm.Barrier()
    safe_print(f"\nProcesul {rank}: Înmulțirea pe inel completată!")
    safe_print(f"Procesul {rank}: Suma totală = {np.sum(result)}")

if __name__ == "__main__":
    main()
