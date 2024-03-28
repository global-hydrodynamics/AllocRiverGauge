      program allocate_gauge
! ===============================================
! to allocate river gauging stations with "lat, lon, uparea" information.
! - Input data is in text format (CSV or SpaceSeparated) : Sample data for GRDC gauge is in input directory

! allocatiin can be done for global map (MERIT Hydro) or Japan regional map (J-FlwDir)
! - Specify input file name and region option "global/japan" as 1st and 2nd arguments.

! output file is gauge_alloc.txt, which contains original and allocated gauge info (lat, lon, area) with error info.
! ===============================================
      implicit none
! index coarse river map
      integer            ::  iXX, iYY, jXX, jYY, dXX, dYY
      integer            ::  nXX, nYY                        !! x-y dimention
      real               ::  gsize                           !! grid size [degree]
      real               ::  west, north, east, south        !! CaMa map domain
      integer            ::  ios
! input
      real,allocatable   ::  uparea(:,:)                     !! drainage area (GRID base)
      real,allocatable   ::  glon(:), glat(:)                !! longitude, latitude

      integer*8          ::  id
      real               ::  lat0, lon0, area0               !! from input data

      real               ::  lat,  lon,  area                !! allocated data
      integer            ::  kXX,  kYY                       !! allocated iXX,iYY

      integer            ::  nn                              !! search domain
            
      real               ::  err_are, err_are0               !! uparea error
      real               ::  err_loc, err_loc0               !! location error
      real               ::  score_all, score_all0           !! area+loc error

      real               ::  dkm,     dkm0                   !! difference in km
      real               ::  diff                            !! difference area
      real               ::  rate
      real               ::  err_adj, err_adj0               !! adjusted error score (-100% equivalent to +300%, -80% ~~ + 150%, -50% ~~ +60% )
! file
      character*16       ::  region                          !! global or japan
      character*128      ::  rivmap                          !! CaMa-Flood map directory
      character*128      ::  rfile1
      character*128      ::  gaugelist                       !! input river gauge list
      character*128      ::  wfile1                          !! output file
! ===============================================
      call getarg(1,gaugelist)
      call getarg(2,region)

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
      write(21,'(a,a)') '          ID   lat_alloc   lon_alloc  area_alloc     lat_ori     lon_ori    area_ori', &
                        '   area_diff  area_error loc_km_diff alloc_score      ix      ix'

! ----------
 1000 continue
      !! read input gauge list
      read(11,*,end=1090) id, lat0, lon0, area0
      !! first guess iXX,iYY
      iXX=int( (lon0 -west)/gsize )+1
      iYY=int( (north-lat0)/gsize )+1

      if( iXX<=0 .or. iXX>nXX .or. iYY<=0 .or. iYY>nYY )goto 1000  ! out of domain
      print '(i8,3f12.3)', id, lat0, lon0, area0   !! lat, lon. uparea of input data

      score_all0=1.e20
      err_are0=1.e20

      !! search radius depending on uparea
      nn=10
      if( area0>1000    ) nn=12
      if( area0>10000   ) nn=14
      if( area0>100000  ) nn=16
      if( area0>300000  ) nn=18
      if( area0>1000000 ) nn=20

      !! search domain for high-res map
      if( trim(region)=='japan05' ) nn=nn*5

      !! search nearby grids to find the best allocation location (minimum error rate)
      do dYY=-nn, nn
        do dXX=-nn, nn
          jXX=iXX+dXX
          jYY=iYY+dYY
          if( jXX<=0 ) jXX=jXX+nXX
          if( jXX>nXX) jXX=jXX-nXX

          if( jYY>0 .and. jYY<=nYY )then
            if( uparea(jXX,jYY)<area0*0.05 )cycle !! skip grid with small uparea compared to input value
            !! error for upstream area
            err_are=(uparea(jXX,jYY)-area0)/area0

            !! error for location mismatch
            dkm=rgetlen( lon0,lat0, glon(jXX),glat(jYY))
            err_loc= dkm / min(area0**0.5,10.) *2.0  !! 200% error for 10km location error for river larger than 100km2. Larger error for smaller rivers.


            !! convert under-estimation rate to equivalent overestimation percentage
            if( err_are>=0 )then  !! over-estimation --> how much & overestimated
              rate=uparea(jXX,jYY)/area0
              err_adj=err_are
            elseif( err_are>-1 .and. err_are<0 )then  !! underestimation (e.g. 80% overestimation and 80% underestimation has different meaning)
              rate= area0 / uparea(jXX,jYY)      !! first, calculate ratio 'how many times underestimated. 50% underestimate: reported is 2 times large as allocated'
              rate=min(rate,1000.)
              err_adj= - (rate - 1)              !! assume "twice of reported value" and "half of reported value" has the same weight. Calculate equivalent underestimation percentage.
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

            if( abs(score_all)<abs(score_all0) )then  !! when error rate is smaller than previous allocated location, replace.
              score_all0=score_all   !! error considering location difference
              err_are0=err_are   !! error of upstream area
              err_adj0=err_adj
              err_loc0=err_loc
              dkm0=dkm
    
              kXX =jXX
              kYY =jYY
              area=uparea(kXX,kYY)
              lon =glon(kXX)
              lat =glat(kYY)
            endif
          endif
        end do
      end do

      !! when pixel to allocate was found
      if( score_all0<1.e20 .and. area0>0 )then
        diff=area-area0
        write(21,'(i12,10f12.3,2i8)') id, lat,lon,area, lat0,lon0,area0, diff, err_are0, dkm0, abs(score_all0), kXX, kYY


      !! if pixels to allocate was not found
      else
        kXX=-999
        kYY=-999
        lon=0
        lat=0
        area=0
        score_all0=-999
        err_are0=-999
        diff=-999.
        dkm0=-999
        write(21,'(i12,10f12.3, 2i8)') id, lat,lon,area, lat0,lon0,area0, diff, err_are0, dkm0, abs(score_all0), kXX, kYY
        print '(a20,i8,4f12.3)', '-----NotAllocated:  ', id, lat0,lon0,area0, uparea(iXX,iYY)
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
