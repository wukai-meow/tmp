      SUBROUTINE MYDUMP(II,JUNIT)
*
*
*       COMMON save or read.
*       --------------------
*
      IMPLICIT REAL*8  (A-H,O-Z)
      INCLUDE 'params.h'
      INCLUDE 'timing.h'
      INCLUDE 'mpi_base.h'
      INCLUDE 'tlist.h'
#ifdef TT
      INCLUDE 'tt.h'
#endif
      PARAMETER  (NA=85,NB=168,NC=530,ND=381+MLR+MLD+MLV,NE=24,NM=40,
     &    NG=132,NL=99,NO=20*MCL+16,NP=32*NTMAX,NQ=31*MMAX,
     &    NS=44*MMAX)
      REAL*4  B,C,D,E,G,L,M,O,P,Q,S
      INTEGER K,I,NTSAVE,NPARTMP(10),KSTAR,NCOMM,IA
*
      COMMON/NAMES/  NTOT,NPAIRS,NTTOT,IA(NA)
      COMMON/COUNTS/ B(NB)
      COMMON/PARAMS/ C(NC)
      COMMON/STARS/  D(ND)
      COMMON/PLPOT/  E(NE)
      COMMON/BLOCKS/ G(NG),KVEC(2*KMAX)
      COMMON/RAND2/  L(NL)
      COMMON/GALAXY/ M(NM)
      COMMON/CLOUDS/ O(NO)
      COMMON/MODES/  P(NP)
      COMMON/RCHE/   Q(NQ)
      COMMON/BINARY/ S(NS)

      COMMON/NBODY/  X(3,NMAX),XDOT(3,NMAX),X0(3,NMAX),X0DOT(3,NMAX),
     &               F(3,NMAX),FDOT(3,NMAX),BODY(NMAX),RS(NMAX),
     &               FI(3,NMAX),D1(3,NMAX),D2(3,NMAX),D3(3,NMAX),
     &               FR(3,NMAX),D1R(3,NMAX),D2R(3,NMAX),D3R(3,NMAX),
     &               STEP(NMAX),T0(NMAX),STEPR(NMAX),T0R(NMAX),
     &               TIMENW(NMAX),RADIUS(NMAX),TEV(NMAX),TEV0(NMAX),
     &               BODY0(NMAX),EPOCH(NMAX),SPIN(NMAX),XSTAR(NMAX),
     &               ZLMSTY(NMAX),FIDOT(3,NMAX),D0(3,NMAX),
     &               FRDOT(3,NMAX),D0R(3,NMAX),KSTAR(NMAX),NAME(NMAX),
     &               IMINR(NMAX),LIST(LMAX,NMAX)
*
      COMMON/PAIRS/  U(4,KMAX),U0(4,KMAX),UDOT(4,KMAX),FU(4,KMAX),
     &               FUDOT(4,KMAX),FUDOT2(4,KMAX),FUDOT3(4,KMAX),
     &               H(KMAX),HDOT(KMAX),HDOT2(KMAX),HDOT3(KMAX),
     &               HDOT4(KMAX),DTAU(KMAX),TDOT2(KMAX),TDOT3(KMAX),
     &               R(KMAX),R0(KMAX),GAMMA(KMAX),SF(7,KMAX),H0(KMAX),
     &               FP0(4,KMAX),FD0(4,KMAX),KBLIST(10*KMAX),
     &               KSLOW(KMAX),DTGW(KMAX),TBLIST
*
      REAL*8 CC(265)
      EQUIVALENCE (CC(1),C(1))
*
      CHARACTER*27 FILE(2)
      CHARACTER*20 TCHAR
      CHARACTER*7 FRAG(2)
      DATA FRAG/'comm.1_','comm.2_'/
      DATA J0/0/
      SAVE J
*
*       Read or save all COMMON variables (valid for tape or disc).
      IF (II.NE.0) THEN

         if(rank.eq.0) then
*     Save comm.n data in separate files split by time
*     Make sure TTOT is still in CC(158) see common6.h
         TTOT = CC(158)
         DTADJ = CC(3)
         IF(J0.EQ.0)THEN
           J = J0 + 200
           J0 = 1
         END IF
         J = J + 1
         NCOMM = IA(16)
         IF(MOD(J-201,NCOMM).EQ.0)THEN
         call string_left(TCHAR,TTOT,DTADJ)
         write(FILE(JUNIT),118) FRAG(JUNIT),TCHAR
 118     format(A7,A20)
         print*,' MYDUMP ',TTOT,TCHAR,J,FILE(JUNIT)
      OPEN (UNIT=J,STATUS='UNKNOWN',FORM='UNFORMATTED',FILE=FILE(JUNIT))
*
*     Also write params.h to help data transfer
            NPARTMP(1) = NMAX
            NPARTMP(2) = KMAX
            NPARTMP(3) = LMAX
            NPARTMP(4) = MMAX
            NPARTMP(5) = MLD
            NPARTMP(6) = MLR
            NPARTMP(7) = MLV
            NPARTMP(8) = MCL
            NPARTMP(9) = NCMAX
            NPARTMP(10) = NTMAX
*
            PRINT*,' W MYDUMP J,II,NPARTMP=',J,II,NPARTMP,
     *             ' ntot,npairs,nttot=',ntot,npairs,nttot,
     *      ' sum na+...+ns=',NA+NB+NC+ND+NE+NG+NL+NM+NO+NP+NQ+NS
            PRINT*,' NA-NS=',NA,NB,NC,ND,NE,NG,NL,NM,NO,NP,NQ,NS
*
            WRITE (J) NPARTMP
*     
            WRITE (J) ntot,npairs,nttot,ia,b,c,d,e,g,l,m,o,p,q,s
         END IF
       end if
*
*       Check expanding arrays to include possible tidal tails (up to NTTOT).
        NTSAVE = NTOT
        IF (NTTOT.GT.0) THEN
            NTOT = NTTOT
        END IF
*
        if(rank.eq.0)then
         IF(MOD(J-201,NCOMM).EQ.0)THEN
        WRITE (J) ((x(k,i),k=1,3),i=1,ntot),((x0(k,i),k=1,3),i=1,ntot),
     *   ((x0dot(k,i),k=1,3),i=1,ntot),((xdot(k,i),k=1,3),i=1,ntot),
     *   ((f(k,i),k=1,3),i=1,ntot),((fdot(k,i),k=1,3),i=1,ntot),
     *   (body(i),i=1,ntot),(rs(i),i=1,ntot),
     *   ((fi(k,i),k=1,3),i=1,ntot),((d1(k,i),k=1,3),i=1,ntot),
     *   ((d2(k,i),k=1,3),i=1,ntot),((d3(k,i),k=1,3),i=1,ntot),
     *   ((fr(k,i),k=1,3),i=1,ntot),((d1r(k,i),k=1,3),i=1,ntot),
     *   ((d2r(k,i),k=1,3),i=1,ntot),((d3r(k,i),k=1,3),i=1,ntot),
     *   (step(i),i=1,ntot),(t0(i),i=1,ntot),(stepr(i),i=1,ntot),
     *   (t0r(i),i=1,ntot),(timenw(i),i=1,ntot),(radius(i),i=1,ntot),
     *   (tev(i),i=1,ntot),
     *   (tev0(i),i=1,ntot),(body0(i),i=1,ntot),(epoch(i),i=1,ntot),
     *   (spin(i),i=1,ntot),(xstar(i),i=1,ntot),(zlmsty(i),i=1,ntot),
     *   ((fidot(k,i),k=1,3),i=1,ntot),((d0(k,i),k=1,3),i=1,ntot),
     *   ((frdot(k,i),k=1,3),i=1,ntot),((d0r(k,i),k=1,3),i=1,ntot),
     *   (kstar(i),i=1,ntot),(iminr(i),i=1,ntot),(name(i),i=1,ntot)
*
        write (J) ((u(k,i),k=1,4),i=1,npairs),((u0(k,i),k=1,4),i=1,
     *    npairs),((udot(k,i),k=1,4),i=1,npairs),((fu(k,i),k=1,4),i=1,
     *    npairs),((fudot(k,i),k=1,4),i=1,npairs),((fudot2(k,i),k=1,4),
     *    i=1,npairs),((fudot3(k,i),k=1,4),i=1,npairs),(h(i),i=1,
     *    npairs),(hdot(i),i=1,npairs),(hdot2(i),i=1,npairs),  
     *    (hdot3(i),i=1,npairs),(hdot4(i),i=1,npairs),(dtau(i),
     *    i=1,npairs),(tdot2(i),i=1,npairs),(tdot3(i),i=1,npairs),
     *    (r(i),i=1,npairs),(r0(i),i=1,npairs),(gamma(i),i=1,npairs),
     *    ((sf(k,i),k=1,7),i=1,npairs),(h0(i),i=1,npairs),((fp0(k,i), 
     *    k=1,4),i=1,npairs),((fd0(k,i),k=1,4),i=1,npairs),
     *    (kblist(i),i=1,10*npairs),(kslow(i),i=1,npairs),tblist
*
        write (J) (list(1,i),(list(k,i),k=2,list(1,i)+1),i=1,ntot)
*
        write (J) NXTLIMIT,NGHOSTS,NXTLST(1:NXTLIMIT+NGHOSTS),NXTLEN,
     *       NDTK(1:64),NDTMIN,NDTMAX,NXTLEVEL,
     *       (NLSTDELAY(K),K=1,NLSTDELAY(1)+1)
*
#ifdef TT
*** FlorentR
        write (J) ttunit,tnowsave,ttmode,nbtt,indtt,ikeypot(1:11)
        write (J) (((ttens(k,i,kk),k=1,3),i=1,3),kk=1,nbtt),
     *       ((tteff(k,i),k=1,3),i=1,3),((dtteff(k,i),k=1,3),i=1,3),
     *       (tttime(i),i=1,nbtt),(tteigen(k),k=1,3),
     &       ((tteigenv(k,i),k=1,3),i=1,3),(ttrtide(k),k=1,3)
*** FRenaud
#endif
        END FILE J
        CLOSE (UNIT=J)
        END IF
        end if
*
*       Restore standard array pointer.
        NTOT = NTSAVE
      else
        if(rank.eq.0) then
*
        J = II + 1
        OPEN (UNIT=J,STATUS='UNKNOWN',FORM='UNFORMATTED',FILE='comm.1')
           READ (J) NPARTMP

*     Safe check
            IF(NPARTMP(4).NE.INT(MMAX)) then
               write(6,*) 'Error! MMAX mismatch (Data:',NPARTMP(4),
     &             'Current:', MMAX
               call flush(6)
               call abort()
            END IF
*
           IF(NPARTMP(5).NE.INT(MLD)) then
              write(6,*) 'Error! MLD mismatch (Data:',NPARTMP(5),
     &             'Current:', MLD
              call flush(6)
              call abort()
           END IF

           IF(NPARTMP(6).NE.INT(MLR)) then
              write(6,*) 'Error! MLR mismatch (Data:',NPARTMP(6),
     &             'Current:', MLR
              call flush(6)
*             call abort()
           END IF

           IF(NPARTMP(7).NE.INT(MLV)) then
              write(6,*) 'Error! MLV mismatch (Data:',NPARTMP(7),
     &       'Current:', MLV
              call flush(6)
              call abort()
           END IF

           IF(NPARTMP(8).NE.INT(MCL)) then
              write(6,*) 'Error! MCL mismatch (Data:',NPARTMP(8),
     &        'Current:',MCL
              call flush(6)
              call abort()
           END IF

           IF(NPARTMP(9).NE.INT(NCMAX)) then
              write(6,*) 'Error! NCMAX mismatch (Data:',NPARTMP(9),
     &        'Current:',NCMAX
              call flush(6)
              call abort()
           END IF

           IF(NPARTMP(10).NE.INT(NTMAX)) then
              write(6,*) 'Error! NTMAX mismatch (Data:',NPARTMP(10),
     &            'Current:' ,NTMAX
              call flush(6)
              call abort()
           END IF
           
           READ (J) ntot,npairs,nttot,ia,b,c,d,e,g,l,m,o,p,q,s

            PRINT*,' R MYDUMP J,II,NPARTMP=',J,II,NPARTMP,
     *             ' ntot,npairs,nttot=',ntot,npairs,nttot,
     *      ' sum na+...+ns=',NA+NB+NC+ND+NE+NG+NL+NM+NO+NP+NQ+NS
            PRINT*,' NA-NS=',NA,NB,NC,ND,NE,NG,NL,NM,NO,NP,NQ,NS

        end if
*
        if (rank.eq.0.and.ntot.gt.nmax) then
          write (*,*) "DANGER NTOT ",ntot," > NMAX ",nmax,"!"
          call flush(6)
          stop
        end if

        if (rank.eq.0.and.npairs.gt.kmax) then
          write (*,*) "DANGER NPAIRS ",npairs," > KMAX ",kmax,"!"
          call flush(6)
          stop
        end if

        if (rank.eq.0.and.NPARTMP(3).gt.LMAX) then
          write (*,*) "DANGER OLD LMAX ",NPARTMP(3)," > NEW LMAX ",LMAX,
     &          "!"
          call flush(6)
          stop
        end if

        NTSAVE = NTOT
        IF (NTTOT.GT.0) THEN
            NTOT = NTTOT
        END IF
        if(rank.eq.0)then 
        read (J) ((x(k,i),k=1,3),i=1,ntot),((x0(k,i),k=1,3),i=1,ntot),
     *   ((x0dot(k,i),k=1,3),i=1,ntot),((xdot(k,i),k=1,3),i=1,ntot),
     *   ((f(k,i),k=1,3),i=1,ntot),((fdot(k,i),k=1,3),i=1,ntot),
     *   (body(i),i=1,ntot),(rs(i),i=1,ntot),
     *   ((fi(k,i),k=1,3),i=1,ntot),((d1(k,i),k=1,3),i=1,ntot),
     *   ((d2(k,i),k=1,3),i=1,ntot),((d3(k,i),k=1,3),i=1,ntot),
     *   ((fr(k,i),k=1,3),i=1,ntot),((d1r(k,i),k=1,3),i=1,ntot),
     *   ((d2r(k,i),k=1,3),i=1,ntot),((d3r(k,i),k=1,3),i=1,ntot),
     *   (step(i),i=1,ntot),(t0(i),i=1,ntot),(stepr(i),i=1,ntot),
     *   (t0r(i),i=1,ntot),(timenw(i),i=1,ntot),(radius(i),i=1,ntot),
     *   (tev(i),i=1,ntot),
     *   (tev0(i),i=1,ntot),(body0(i),i=1,ntot),(epoch(i),i=1,ntot),
     *   (spin(i),i=1,ntot),(xstar(i),i=1,ntot),(zlmsty(i),i=1,ntot),
     *   ((fidot(k,i),k=1,3),i=1,ntot),((d0(k,i),k=1,3),i=1,ntot),
     *   ((frdot(k,i),k=1,3),i=1,ntot),((d0r(k,i),k=1,3),i=1,ntot),
     *   (kstar(i),i=1,ntot),(iminr(i),i=1,ntot),(name(i),i=1,ntot)
*
        read (J) ((u(k,i),k=1,4),i=1,npairs),((u0(k,i),k=1,4),i=1,
     *    npairs),((udot(k,i),k=1,4),i=1,npairs),((fu(k,i),k=1,4),i=1,
     *    npairs),((fudot(k,i),k=1,4),i=1,npairs),((fudot2(k,i),k=1,4),
     *    i=1,npairs),((fudot3(k,i),k=1,4),i=1,npairs),(h(i),i=1,
     *    npairs),(hdot(i),i=1,npairs),(hdot2(i),i=1,npairs),
     *    (hdot3(i),i=1,npairs),(hdot4(i),i=1,npairs),(dtau(i),
     *    i=1,npairs),(tdot2(i),i=1,npairs),(tdot3(i),i=1,npairs),
     *    (r(i),i=1,npairs),(r0(i),i=1,npairs),(gamma(i),i=1,npairs),
     *    ((sf(k,i),k=1,7),i=1,npairs),(h0(i),i=1,npairs),((fp0(k,i),
     *    k=1,4),i=1,npairs),((fd0(k,i),k=1,4),i=1,npairs),
     *    (kblist(i),i=1,10*npairs),(kslow(i),i=1,npairs),tblist
*
         read (J) (list(1,i),(list(k,i),k=2,list(1,i)+1),i=1,ntot)
*
        read (J) NXTLIMIT,NGHOSTS,NXTLST(1:NXTLIMIT+NGHOSTS),NXTLEN,
     *       NDTK(1:64),NDTMIN,NDTMAX,NXTLEVEL,NLSTDELAY(1),
     *       (NLSTDELAY(K),K=2,NLSTDELAY(1)+1)

#ifdef TT
*** FlorentR
        read (J) ttunit,tnowsave,ttmode,nbtt,indtt,ikeypot(1:11)
        if (nbtt.gt.nbttmax.AND.TTMODE.EQ.1) then
           write (*,*) "DANGER NBTT > NBTTMAX !"
           stop
        end if

        read (J) (((ttens(k,i,kk),k=1,3),i=1,3),kk=1,nbtt),
     *       ((tteff(k,i),k=1,3),i=1,3),((dtteff(k,i),k=1,3),i=1,3),
     *       (tttime(i),i=1,nbtt),(tteigen(k),k=1,3),
     *       ((tteigenv(k,i),k=1,3),i=1,3),(ttrtide(k),k=1,3)

#endif

        end if

*     Reinitialize KVEC
        DO K = 1,KMAX
           KVEC(2*K-1) = K
           KVEC(2*K) = K
        END DO
      END IF

#ifdef PARALLEL
        call cputim(tt998)
        CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
        call cputim(tt999)
        ttbar = ttbar + (tt999-tt998)*60
        ibarcount=ibarcount+1

*
*     READ ntot,npairs,nttot,a,b,c,d,e,g,l,m,o,p,q,s
*     --04/25/13 10:16-lwang-debug--------------------------------------*
***** Note: add MPI_BCAST of ntsave since it last used to initial ntot-**
         CALL MPI_BCAST(ntsave,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
*     --04/25/13 10:17-lwang-end-debug----------------------------------*
         CALL MPI_BCAST(ntot,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(npairs,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(nttot,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(IA(1),NA,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(B(1),NB,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(C(1),NC,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(D(1),ND,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(E(1),NE,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(G(1),NG,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(L(1),NL,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(M(1),NM,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(O(1),NO,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(P(1),NP,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(Q(1),NQ,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
         CALL MPI_BCAST(S(1),NS,MPI_REAL4,0,MPI_COMM_WORLD,ierr)
*
*       read (J) x,x0,xn,xndot,x0dot,f,fdot,xdot (3,ntot)
*                fi,d1,d2,d3,fr,d1r,d2r,d3r,fidot,d0,frdot,d0r (3,ntot)
*                body, rs, step, t0, stepr, t0r,timenw,radius, tev (ntot)
*                tev0,body0,epoch,spin,xstar,zlmsty,kstar (ntot),iminr(ntot)
       CALL MPI_BCAST(X(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(XDOT(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(X0(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(X0DOT(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(F(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FDOT(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FI(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D1(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D2(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D3(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FR(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D1R(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D2R(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D3R(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FIDOT(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D0(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FRDOT(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(D0R(1,1),3*NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(BODY(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(RS(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(STEP(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(T0(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(STEPR(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(T0R(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(TIMENW(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(RADIUS(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(TEV(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(TEV0(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(BODY0(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(EPOCH(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(SPIN(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(XSTAR(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(ZLMSTY(1),NTOT,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(KSTAR(1),NTOT,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(IMINR(1),NTOT,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
*
*       read u,u0,udot,fu,fudot,fudot2,fudot3,fp0,fd0 (4,npairs) sf(7,npairs)
*            h,hdot,hdot2,hdot3,hdot4,dtau,tdot2,tdot3,r,r0,gamma,h0 (npairs)
*            tblist,dtb      (real)        kblist (10*kmax), kslow(npairs) name(ntot)
       CALL MPI_BCAST(SF(1,1),7*NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(U(1,1),4*NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(U0(1,1),4*NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(UDOT(1,1),4*NPAIRS,MPI_REAL8,0,
     &      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FU(1,1),4*NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FUDOT(1,1),4*NPAIRS,MPI_REAL8,0,
     &                                      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FUDOT2(1,1),4*NPAIRS,MPI_REAL8,0,
     &                                      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FUDOT3(1,1),4*NPAIRS,MPI_REAL8,0,
     &                                      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FP0(1,1),4*NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(FD0(1,1),4*NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(H(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(HDOT(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(HDOT2(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(HDOT3(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(HDOT4(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(DTAU(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(TDOT2(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(TDOT3(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(R(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(R0(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(GAMMA(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(H0(1),NPAIRS,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(TBLIST,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(KBLIST(1),10*NPAIRS,MPI_INTEGER,0,
     &                                      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(KSLOW(1),NPAIRS,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(DTGW(1),NPAIRS,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NAME(1),NTOT,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
*
*     read list(1,i),(list(k,i),k=2,list(1,i)+1),i=1,ntot)
       CALL MPI_BCAST(LIST(1,1),LMAX*NTOT/2,MPI_INTEGER,0,
     &                                      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(LIST(1,NTOT/2+1),LMAX*NTOT/2,MPI_INTEGER,0,
     &                                      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NXTLIMIT,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NXTLST(1),NMAX,MPI_INTEGER,0,MPI_COMM_WORLD,
     &      ierr)
       CALL MPI_BCAST(NXTLEN,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NDTK(1),64,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NDTMIN,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NDTMAX,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NXTLEVEL,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NLSTDELAY(1),NDELAYMAX,MPI_INTEGER,0,
     &      MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(NGHOSTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
*
#ifdef TT
       CALL MPI_BCAST(ttunit,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(tnowsave,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(ttmode,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(nbtt,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(INDTT,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(ikeypot(1),11,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(ttens(1,1,1),9*nbtt,MPI_REAL8,0,MPI_COMM_WORLD,
     &      ierr)
       CALL MPI_BCAST(tteff(1,1),9,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(dtteff(1,1),9,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(tttime(1),nbtt,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(tteigen(1),3,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(tteigenv(1,1),9,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
       CALL MPI_BCAST(ttrtide(1),3,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
#endif
       call cputim(tt998)
       CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
       call cputim(tt999)
       ttbar = ttbar + (tt999-tt998)*60
       ibarcount=ibarcount+1
#endif         
*
        NTOT = NTSAVE
*
      RETURN
*
      END
