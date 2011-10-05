      program tryMe
      include "mpif.h"
   
      integer ierr, myProc, nProc

      call MPI_init(ierr)

  
      call MPI_Comm_rank(MPI_COMM_WORLD, myProc, ierr)
      call MPI_Comm_size(MPI_COMM_WORLD, nProc,  ierr)

      if (myProc == 0) then
        write(*,1000) myProc, nProc
      endif
      call MPI_Finalize(ierr);
 1000 format("Hello World from proc: ",i5," out of ",i5,"!")
      end
