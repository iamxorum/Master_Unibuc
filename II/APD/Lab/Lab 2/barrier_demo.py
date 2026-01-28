#!/usr/bin/env python3

from mpi4py import MPI
import time
import random
import sys

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    def safe_print(*args, **kwargs):
        print(*args, **kwargs, flush=True)
    
    safe_print(f"Procesul {rank}: inițializat, total {size} procese")
    
    # pas 1 - root simuleaza activitatea
    if rank == 0:
        safe_print(f"\n=== Procesul ROOT ({rank}) începe activitatea ===")
        safe_print(f"Procesul {rank}: simulez activitate (dorm 4 secunde)...")
        time.sleep(4)
        safe_print(f"Procesul {rank}: Activitatea root a fost finalizată!")
    
    # pas 2 - toate procesele asteapta sa termine root
    safe_print(f"Procesul {rank}: aștept la prima barieră...")
    comm.Barrier()
    
    # pas 3 - procesele slave se pregatesc
    if rank != 0:
        safe_print(f"Procesul {rank}: Mă pregătesc de lucru (și de sleep)...")
    
    # pas 4 - toate procesoarele simuleaza activitate aleatoare
    sleep_time = random.uniform(0, 10)
    safe_print(f"Procesul {rank}: simulez activitate aleatoare ({sleep_time:.2f} secunde)...")
    time.sleep(sleep_time)
    safe_print(f"Procesul {rank}: Activitatea aleatoare finalizată!")
    
    # pas 5 - toate procesele se sincronizeaza
    safe_print(f"Procesul {rank}: aștept la a doua barieră pentru sincronizare...")
    comm.Barrier()
    
    # pas 6 - root confirma finalizarea
    if rank == 0:
        safe_print(f"\n=== Procesul ROOT ({rank}) confirmă ===")
        safe_print(f"TOATE PROCESELE au terminat activitatea cu succes!")
        safe_print(f"Total procese participante: {size}")

if __name__ == "__main__":
    main()
