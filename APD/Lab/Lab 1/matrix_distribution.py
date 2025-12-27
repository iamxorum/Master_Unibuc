from mpi4py import MPI
import numpy as np

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    # Dimensiunea matricei (n >= p)
    n = 2 # matrice 2x2
    if n < size:
        n = size  # asigură că n >= p
    
    print(f"Procesul {rank}: matrice {n}x{n}, {size} procese")
    
    # Procesul 0 generează matricea
    if rank == 0:
        matrix = np.random.randint(1, 10, (n, n))
        print(f"Procesul {rank}: matrice generată:")
        print(matrix)
    else:
        matrix = None
    
    # === DISTRIBUȚIA PE LINII ===
    print(f"\n=== DISTRIBUȚIA PE LINII ===")
    distribute_by_rows(comm, matrix, n, rank, size)
    
    # === DISTRIBUȚIA PE COLOANE ===
    print(f"\n=== DISTRIBUȚIA PE COLOANE ===")
    distribute_by_columns(comm, matrix, n, rank, size)
    
    # === DISTRIBUȚIA PE BLOCURI ===
    print(f"\n=== DISTRIBUȚIA PE BLOCURI ===")
    distribute_by_blocks(comm, matrix, n, rank, size)

def distribute_by_rows(comm, matrix, n, rank, size):
    """Distribuie matricea pe linii"""
    if rank == 0:
        # Împarte matricea pe linii
        rows_per_process = n // size
        for i in range(size):
            start_row = i * rows_per_process
            end_row = start_row + rows_per_process
            if i == size - 1:  # ultimul proces ia și restul
                end_row = n
            
            local_rows = matrix[start_row:end_row, :]
            if i == 0:
                my_rows = local_rows
            else:
                comm.send(local_rows, dest=i, tag=0)
        
        print(f"Procesul {rank}: am trimis linii către toate procesele")
    else:
        my_rows = comm.recv(source=0, tag=0)
    
    print(f"Procesul {rank}: am primit {my_rows.shape[0]} linii")
    print(f"Procesul {rank}: linii locale:\n{my_rows}")

def distribute_by_columns(comm, matrix, n, rank, size):
    """Distribuie matricea pe coloane"""
    if rank == 0:
        # Împarte matricea pe coloane
        cols_per_process = n // size
        for i in range(size):
            start_col = i * cols_per_process
            end_col = start_col + cols_per_process
            if i == size - 1:  # ultimul proces ia și restul
                end_col = n
            
            local_cols = matrix[:, start_col:end_col]
            if i == 0:
                my_cols = local_cols
            else:
                comm.send(local_cols, dest=i, tag=1)
        
        print(f"Procesul {rank}: am trimis coloane către toate procesele")
    else:
        my_cols = comm.recv(source=0, tag=1)
    
    print(f"Procesul {rank}: am primit {my_cols.shape[1]} coloane")
    print(f"Procesul {rank}: coloane locale:\n{my_cols}")

def distribute_by_blocks(comm, matrix, n, rank, size):
    """Distribuie matricea pe blocuri"""
    if rank == 0:
        # Calculează dimensiunea blocurilor - simplificat pentru primul curs
        block_size = max(1, n // size)  # fiecare proces primește un bloc
        
        blocks_sent = 0
        for i in range(0, n, block_size):
            if blocks_sent >= size:
                break
                
            end_i = min(i + block_size, n)
            block = matrix[i:end_i, :]  # bloc de linii
            
            if blocks_sent == 0:
                my_block = block
            else:
                comm.send(block, dest=blocks_sent, tag=2)
            
            blocks_sent += 1
        
        print(f"Procesul {rank}: am trimis {blocks_sent} blocuri")
    else:
        my_block = comm.recv(source=0, tag=2)
    
    print(f"Procesul {rank}: am primit blocul de dimensiuni {my_block.shape}")
    print(f"Procesul {rank}: blocul local:\n{my_block}")

if __name__ == "__main__":
    main()
