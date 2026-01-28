from mpi4py import MPI
import numpy

def matvec(comm, A, x):
    m = A.shape[0] # local rows
    p = comm.Get_size()
    rank = comm.Get_rank()
    
    print(f"Procesul {rank}: încep înmulțirea matrice-vector")
    print(f"Procesul {rank}: matrice locală A - dimensiuni {A.shape}")
    print(f"Procesul {rank}: vector local x - dimensiuni {x.shape}")
    
    xg = numpy.zeros(m*p, dtype='d')
    print(f"Procesul {rank}: pregătesc vectorul global xg - dimensiuni {xg.shape}")
    
    print(f"Procesul {rank}: încep Allgather pentru a colecta vectorul complet")
    comm.Allgather([x,  MPI.DOUBLE],
                   [xg, MPI.DOUBLE])
    
    print(f"Procesul {rank}: Allgather completat, calculez înmulțirea locală")
    y = numpy.dot(A, xg)
    print(f"Procesul {rank}: înmulțirea completată, rezultat local - dimensiuni {y.shape}")
    
    return y

if __name__ == "__main__":
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    m = 2  # rânduri per proces
    n = m * size  # dimensiunea totală
    
    # Matricea locală (m x n)
    A = numpy.random.rand(m, n)
    # Vectorul local (m elemente)
    x = numpy.random.rand(m)
    
    print(f"Procesul {rank}: testez înmulțirea matrice-vector paralelă")
    print(f"Procesul {rank}: matrice globală {m}x{n}, vector global {n}x1")
    
    y = matvec(comm, A, x)
    
    print(f"Procesul {rank}: rezultat final - primul element: {y[0]:.3f}")