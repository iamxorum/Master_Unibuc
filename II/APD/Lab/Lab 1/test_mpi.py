#!/usr/bin/env python3
from mpi4py import MPI
import sys

def main():
    # Inițializare MPI
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    # Afișare informații despre procesul curent
    print(f"Procesul {rank} din {size} procese active")
    
    if rank == 0:
        # Procesul master (rank 0)
        print(f"\n=== Procesul MASTER (rank {rank}) ===")
        print(f"Total procese: {size}")
        
        # Trimite mesaje către toate celelalte procese
        for i in range(1, size):
            message = f"Mesaj pentru procesul {i}!"
            comm.send(message, dest=i, tag=0)
            print(f"Am trimis mesaj către procesul {i}")
        
        # Primește răspunsuri de la toate procesele
        for i in range(1, size):
            response = comm.recv(source=i, tag=1)
            print(f"Răspuns de la procesul {i}: {response}")
            
    else:
        # Procesele slave, acelea care au rank > 0
        print(f"\n=== Procesul SLAVE (rank {rank}) ===")
    
        # primeste mesaj de la master
        message = comm.recv(source=0, tag=0)
        print(f"Am primit mesaj: {message}")
        
        # trimite răspuns înapoi la master
        response = f"Procesul {rank} a primit mesajul!"
        comm.send(response, dest=0, tag=1)
        print(f"Am trimis răspuns către master")
    
    # Sincronizare - toate procesele așteaptă aici
    comm.Barrier()
    
    if rank == 0:
        print("\n=== Test completat cu succes! ===")
        print("Toate procesele au terminat execuția.")

if __name__ == "__main__":
    main()
