#include <iostream>
#include "mpi.h"
int main(int argc, char* argv[])
{
  int ierr, myProc, nProc;

  ierr = MPI_Init(&argc, &argv);
  
  MPI_Comm_rank(MPI_COMM_WORLD, &myProc);
  MPI_Comm_size(MPI_COMM_WORLD, &nProc);

  if (myProc == 0)
    std::cout << "Hello World from proc: " << myProc << " out of "<< nProc << "!\n";

  MPI_Finalize();

  return 0;
}
