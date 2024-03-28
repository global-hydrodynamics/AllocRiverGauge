      program allocate_gauge
! ===============================================
! to allocate river gauging stations with "lat, lon" information. (no uparea info)
! Assume lat lon is relatively precise. Get lat-lon from high-resolution CaMa-Food map.
! - Input data is in text format: Sample data for GRDC gauge is in input directory
! ===============================================
      implicit none
! index TRIP
      integer            ::  iXX, iYY, jXX, jYY, dXX, dYY
      integer            ::  nXX, nYY                        !! x-y dimention
      real               ::  gsize                           !! grid size [degree]
      real               ::  west, north, east, south        !! CaMa map domain
      integer            ::  ios
! input
      real,allocatable   ::  uparea(:,:)                     !! drainage area (GRID base)
      real,allocatable   ::  glon(:), glat(:)                !! longitude, latitude

      real               ::  upa_thrs  !! upstream area threshold to allocate river [km2]

      integer*8          ::  id
      real               ::  lat0, lon0                      !! from input data

      real               ::  lat,  lon,  area                !! allocated data
      integer            ::  kXX, kYY                        !! allocated iXX,iYY

      integer            ::  nn                              !! search domain
      real               ::  dkm,  dkm0                      !! difference in km
! file
      character*16       ::  buf
      character*16       ::  region                          !! global or japan
      character*128      ::  rivmap                          !! CaMa-Flood map directory
      character*128      ::  rfile1
      character*128      ::  gaugelist                       !! input river gauge list
      character*128      ::  wfile1                          !! output file
! ===============================================
      call getarg(1,gaugelist)
      call getarg(2,buf)
      read(buf,*) upa_thrs    !! threshold to allocate rivers on pixel (km2)
      call getarg(3,region)

      !! default: region=="global30"
      west=-180.0
      east= 180.0
      south=-90.0
      north= 90.0
      nXX=43200
      nYY=18000
      gsize=1./120.
      rivmap='./30sec_glb/'

      if( trim(region)=='japan05' )then
        west= 120.0
        east= 150.0
        south= 20.0
        north= 50.0
        nXX  = 21600
        nYY  = 21600
        gsize=1./720.
        rivmap='./05sec_jpn/'
      endif

      allocate(uparea(nXX,nYY))

      rfile1='./'//trim(rivmap)//'/uparea.bin'
      open(11, file=rfile1, form='unformatted', access='direct', recl=4*nXX*nYY,status='old',iostat=ios)
      read(11,rec=1) uparea
      close(11)

      !! convert uparea unit from [m2] to [km2]
      do iYY=1, nYY
        do iXX=1, nXX
          if( uparea(iXX,iYY)>0 ) uparea(iXX,iYY)=uparea(iXX,iYY)*1.e-6  
        end do
      end do

      !! set lat lon
      allocate(glon(nXX),glat(nYY))
      do iYY=1, nYY
        glat(iYY)=north-gsize*(iYY-0.5)
      end do
      do iXX=1, nXX
        glon(iXX)= west+gsize*(iXX-0.5)
      end do

! ===============================================
      open(11, file=gaugelist, form='formatted')
      read(11,*) !! skip header

      !! output file
      wfile1='./gauge_alloc.txt'
      open(21, file=wfile1, form='formatted')
      write(21,'(a,a)') '          ID   lat_alloc   lon_alloc  area_alloc     lat_ori     lon_ori', &
                        ' loc_km_diff      ix      ix'

! ----------
 1000 continue
      !! read input gauge list
      read(11,*,end=1090) id, lat0, lon0
      !! first guess iXX,iYY
      iXX=int( (lon0 -west)/gsize )+1
      iYY=int( (north-lat0)/gsize )+1

      dkm0=1.e20

      !! search domain depending on uparea
      nn=10
      if( trim(region)=='japan05' ) nn=nn*2      !! search domain for high-res map

      !! search nearby grids to find the best allocation location 
      do dYY=-nn, nn
        do dXX=-nn, nn
          jXX=iXX+dXX
          jYY=iYY+dYY
          if( jXX<=0 ) jXX=jXX+nXX
          if( jXX>nXX) jXX=jXX-nXX

          if( jYY>0 .and. jYY<=nYY )then
            if( uparea(jXX,jYY)>upa_thrs )then  !! check rivers > upa_thrs
              !! error considering location mismatch
              dkm=rgetlen( lon0,lat0, glon(jXX),glat(jYY))

              !! when location error is smaller than previous ix,iy location, replace.
              if( dkm<dkm0 )then  
                dkm0=dkm
                kXX =jXX
                kYY =jYY
                area=uparea(kXX,kYY)
                lon =glon(kXX)
                lat =glat(kYY)
              endif
            endif
          endif
        end do
      end do

      !! when pixel to allocate was found
      if( dkm0<1.e20 )then
        write(21,'(i12,6f12.3,2i8)') id, lat,lon,area, lat0,lon0, dkm0, kXX, kYY
        print '(i12,6f12.3,2i8)', id, lat,lon,area, lat0,lon0, dkm0, kXX, kYY

      !! if pixels to allocate was not found
      else
        kXX=-999
        kYY=-999
        lon=-999
        lat=-999
        area=-999
        dkm0=-999
        write(21,'(i12,6f12.3,2i8)') id, lat,lon,area, lat0,lon0, dkm0, kXX, kYY
        print *, '-----NotAllocated', id, lat0,lon0
      endif
      goto 1000
 1090 continue

      close(11)
      close(21)

! ====================
      CONTAINS




      real function rgetlen(rlon1, rlat1, rlon2, rlat2)
! ================================================
! to   get the length (km) between (rlon1, rlat1) to (rlon2, rlat2)
! by   nhanasaki
! on   1st Nov 2003
! at   IIS,UT
!
!     see page 643 of Rika-Nenpyo (2000)
!     at the final calculation, earth is assumed to be a sphere
! ================================================
      implicit none
      real                ::  rpi                !! Pi
      double precision    ::  de2                !! eccentricity powered by 2
      double precision    ::  da                 !! the radius of the earth
!
      real                ::  rlon1              !! longitude of the origin
      real                ::  rlon2              !! longitude of the destination
      real                ::  rlat1              !! latitude of the origin
      real                ::  rlat2              !! latitude of the destination
      double precision    ::  dsinlat1           !! sin(lat1)
      double precision    ::  dsinlon1           !! sin(lon1)
      double precision    ::  dcoslat1           !! cos(lat1)
      double precision    ::  dcoslon1           !! cos(lon1)
      double precision    ::  dsinlat2           !! sin(lat2) 
      double precision    ::  dsinlon2           !! sin(lon2)
      double precision    ::  dcoslat2           !! cos(lat2)
      double precision    ::  dcoslon2           !! cos(lon2)
      double precision    ::  dh1                !! hegiht of the origin
      double precision    ::  dn1                !! intermediate val of calculation
      double precision    ::  dx1                !! X coordinate of the origin
      double precision    ::  dy1                !! Y coordinate of the origin
      double precision    ::  dz1                !! Z coordinate of the origin
      double precision    ::  dh2                !! height of the destination
      double precision    ::  dn2                !! intermediate val of calculation
      double precision    ::  dx2                !! X coordinate of the destination
      double precision    ::  dy2                !! Y coordinate of the destination
      double precision    ::  dz2                !! Z coordinate of the destination
!
      double precision    ::  dlen               !! length between origin and destination
      double precision    ::  drad               !! half of the angle
! parameters
      data             da/6378137.0/
      data             de2/0.006694470/
      data             rpi/3.141592/      
! ================================================
! (lon1,lat1) --> (x1,y1,z1)
! ================================================
      dh1=0
      dh2=0

      dsinlat1 = dble(sin(rlat1 * rpi/180))
      dsinlon1 = dble(sin(rlon1 * rpi/180))
      dcoslat1 = dble(cos(rlat1 * rpi/180))
      dcoslon1 = dble(cos(rlon1 * rpi/180))
!
      dn1 = da/(sqrt(1.0-de2*dsinlat1*dsinlat1))
      dx1 = (dn1+dh1)*dcoslat1*dcoslon1
      dy1 = (dn1+dh1)*dcoslat1*dsinlon1
      dz1 = (dn1*(1-de2)+dh1)*dsinlat1
! ================================================
! (lon2,lat2) --> (x2,y2,z2)
! ================================================
      dsinlat2 = dble(sin(rlat2 * rpi/180))
      dsinlon2 = dble(sin(rlon2 * rpi/180))
      dcoslat2 = dble(cos(rlat2 * rpi/180))
      dcoslon2 = dble(cos(rlon2 * rpi/180))
!
      dn2 = da/(sqrt(1.0-de2*dsinlat2*dsinlat2))
      dx2 = (dn2+dh2)*dcoslat2*dcoslon2
      dy2 = (dn2+dh2)*dcoslat2*dsinlon2
      dz2 = (dn2*(1-de2)+dh2)*dsinlat2      
! ================================================
! Calculate length
! ================================================
      dlen=sqrt((dx1-dx2)**2+(dy1-dy2)**2+(dz1-dz2)**2)
      drad=dble(asin(real(dlen/2/da)))
      rgetlen=real(drad*2*da)

      rgetlen=rgetlen*0.001  !! from meter to km
!
      return
      end function rgetlen



      end program allocate_gauge
