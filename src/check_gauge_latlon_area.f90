      program allocate_gauge
! ===============================================
! to check errors of allocate river gauging stations with "lat, lon, uparea" information.
! ===============================================
      implicit none
      integer*8          ::  id
      real               ::  lat2, lon2, area2               !! allocated on MERIT Hydro
      real               ::  lat1, lon1, area1               !! modified reported data
      real               ::  lat0, lon0, area0               !! original reported data
      integer            ::  ix, iy

      real               ::  err_are              !! uparea error
      real               ::  err_loc              !! location error
      real               ::  score_all            !! area+loc error

      real               ::  dkm                  !! difference in km
      real               ::  diff                 !! difference area

      real               ::  rate
      real               ::  err_adj              !! adjusted error score (-100% equivalent to +300%, -80% ~~ + 150%, -50% ~~ +60% )
!
      character*64       ::  modify


! file
      character*128      ::  gaugelist            !! input river gauge list (allocated)
      character*128      ::  gaugeori             !! input river gauge list (original)
      character*128      ::  wfile1               !! output file

      character*64       ::  buf               !! 
! ===============================================
      call getarg(1,gaugelist)
      call getarg(2,gaugeori)

! ===============================================
      open(11, file=gaugelist, form='formatted')
      read(11,*) !! skip header

      open(12, file=gaugeori,  form='formatted')
      read(12,*) !! skip header

      !! output file
      wfile1='./gauge_alloc.txt'
      open(21, file=wfile1, form='formatted')
      write(21,'(a,a)') '          ID   lat_alloc   lon_alloc  area_alloc     lat_ori     lon_ori    area_ori', &
                        '   area_diff  area_error loc_km_diff alloc_score      ix      ix     lat_mod     lon_mod    area_mod      Modify'

! ----------
 1000 continue
      !! read input gauge list
      read(11,*,end=1090) id,  lat2,lon2,area2, buf,buf,buf, buf,buf,buf,buf, ix,iy
      read(12,*,end=1090) buf, lat1,lon1,area1, lat0,lon0,area0
      print *, id, lat0, lon0, area0   !! lat, lon. uparea of input data

      modify=''
      if( lat1 /=lat0 ) modify=trim(modify)//'Lat'
      if( lon1 /=lon0 ) modify=trim(modify)//'Lon'
      if( area1/=area0) modify=trim(modify)//'Area'

      if( ix<=0 )then  !! not allocated
        diff      =-999
        err_are   =-999
        dkm       =-999
        score_all =-999
        write(21,'(i12,10f12.3,2i8,3f12.3,a12)') id, lat2,lon2,area2, lat0,lon0,area0, diff,err_are,dkm,score_all, &
                                                 ix,iy, lat1,lon1,area1, trim(modify)
        goto 1000
      endif

      diff    = (area2-area0)
      err_are = (area2-area0)/area0
      dkm     = rgetlen( lon0,lat0, lon2,lat2 )
      err_loc= dkm / min(area0**0.5,10.) *2.0  !! 200% error for 10km location error for river larger than 100km2. Larger error for smaller rivers.

      !! convert under-estimation rate to equivalent overestimation percentage
      if( err_are>=0 )then  !! over-estimation --> how much & overestimated
        rate=area2/area0
        err_adj=err_are
      elseif( err_are>-1 .and. err_are<0 )then  !! underestimation (e.g. 80% overestimation and 80% underestimation has different meaning)
        rate= area0 / area2                     !! first, calculate ratio 'how many times underestimated. 50% underestimate: reported is 2 times large as allocated'
        rate=min(rate,1000.)
        err_adj= - (rate - 1)                   !! assume "twice of reported value" and "half of reported value" has the same weight. Calculate equivalent underestimation percentage.
                                                !! "twice" is 100% overestimate, "half" equivalent to -100% overestimate. 66% underestimate (one third) equivalent to three times larger -> equivalent to 200% overestimate             else
        err_adj=err_adj*0.75  !! adjustment for comparison (the ratio 0.75 is subjectively decided)
      else
        rate=1000
        err_adj= -(rate - 1) 
        err_adj=err_adj*0.75  !! adjustment
      endif

      if( err_are>=0 ) then
        score_all= err_adj+err_loc
      else
        score_all= err_adj-err_loc
      endif
      score_all=abs(score_all)

      write(21,'(i12,10f12.3,2i8,3f12.3,a12)') id, lat2,lon2,area2, lat0,lon0,area0, diff,err_are,dkm,score_all, &
                                               ix,iy, lat1,lon1,area1, trim(modify)
      goto 1000

 1090 continue

      close(11)
      close(12)
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
