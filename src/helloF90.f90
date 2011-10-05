! -*- f90 -*-
program tryMe
   use mpi
   implicit none 
   
   integer :: ierr, myProc, nProc

   call MPI_init(ierr)

  
   call MPI_Comm_rank(MPI_COMM_WORLD, myProc, ierr)
   call MPI_Comm_size(MPI_COMM_WORLD, nProc,  ierr)

   if (myProc == 0) then
      write(*,'(''Hello World from proc: '',i5,'' out of '',i5,''!'')') myProc, nProc
   endif
   call MPI_Finalize(ierr);

end program tryMe
