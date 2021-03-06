! Module for mingling with the OS

! Fully implemented by Nick Papior Andersen
module m_os

#ifdef MPI
  use mpi_siesta, only : MPI_Bcast, MPI_Comm_World, MPI_Logical
  use mpi_siesta, only : MPI_AllReduce, MPI_LAnd
#endif
  
  implicit none
  
  private
  
  public :: file_exist
  public :: dir_exist

contains

  function file_exist(file, Bcast, Comm, all) result(exist)
    
    character(len=*), intent(in) :: file
    logical, intent(in), optional :: Bcast ! whether it should be b-casted
    integer, intent(in), optional :: Comm ! the communicator (default World)
    logical, intent(in), optional :: all ! whether all Nodes sees the file
    logical :: exist
    
#ifdef MPI
    logical :: all_exist
    integer :: MPIerror, Com
#endif

    ! Now we have all required information
    inquire(file=file, exist=exist)
    
#ifdef MPI
    Com = MPI_Comm_World
    if ( present(Comm) ) Com = Comm
    
    if ( present(Bcast) ) then

     if ( Bcast ) then
       
        call MPI_Bcast(exist,1,MPI_Logical, 0, Com, MPIerror)
       
     end if

    else if ( present(all) ) then

     if ( all ) then

        call MPI_AllReduce(exist, all_exist, 1, MPI_Logical, &
             MPI_LAnd, Com, MPIerror )
        
        exist = all_exist
        
     end if

    end if
#endif

  end function file_exist

  
  function dir_exist(dir, Bcast, Comm, all) result(exist)

    character(len=*), intent(in) :: dir
    logical, intent(in), optional :: Bcast ! whether it should be b-casted
    integer, intent(in), optional :: Comm ! the communicator (default World)
    logical, intent(in), optional :: all ! whether all Nodes sees the file
    logical :: exist
    
    integer :: ldir
#ifdef MPI
    logical :: all_exist
    integer :: MPIerror, Com
#endif

    ! A directory of length 0 is the "top" directory,
    ! of course it exists
    ldir = len_trim(dir)
    if ( ldir == 0 ) then
       exist = .true.
       return
    else if ( ldir == 1 .and. dir(1:1) == '.' ) then
       exist = .true.
       return
    end if
    
    ! Now we have all required information
#ifdef __INTEL_COMPILER
    inquire(directory=dir, exist=exist)
#else
    if ( ldir == 1 ) then
       if ( dir(ldir:ldir) == '/' ) then
          inquire(file=trim(dir)//'.' , exist=exist)
       else
          inquire(file=trim(dir)//'/.', exist=exist)
       end if
    else
       if ( dir(ldir-1:ldir) == '/.' ) then
          inquire(file=trim(dir)      , exist=exist)
       else if ( dir(ldir:ldir) == '/' ) then
          inquire(file=trim(dir)//'.' , exist=exist)
       else
          inquire(file=trim(dir)//'/.', exist=exist)
       end if
    end if
#endif

#ifdef MPI
    Com = MPI_Comm_World
    if ( present(Comm) ) Com = Comm

    if ( present(Bcast) ) then

     if ( Bcast ) then
       
        call MPI_Bcast(exist,1,MPI_Logical, 0, Com, MPIerror)
       
     end if

    else if ( present(all) ) then

     if ( all ) then

        call MPI_AllReduce(exist, all_exist, 1, MPI_Logical, &
             MPI_LAnd, Com, MPIerror )
        
        exist = all_exist

     end if

    end if
#endif

  end function dir_exist

end module m_os
