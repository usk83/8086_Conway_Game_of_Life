CSEG    SEGMENT
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG
        ORG 100H
START:
        ;dsはVRAMのアドレス、esは保存メモリのアドレスに固定
        mov     ax, 0b800h ;VRAMの先頭アドレス
        mov     ds, ax
        mov     ax, 9000h ;保存メモリの先頭アドレス
        mov     es, ax

        ;スクリーンを白クリアする
        mov     ax, 0f000h ;白背景黒文字NULL
        call    CLS ;axに埋め尽くす文字

        ;文字保存メモリの初期化
        ;9000:0~9000:7d0 (2000byte)
        mov     cx, 7d0h ;全文字数
        mov     bx, 0 ;オフセット
INIT:
        mov     ax, 2
        call    RND
        cmp     al, 0
        Jz      INIT1
        mov     al, 2
INIT1:
        mov     es:[bx], al
        inc     bx
        dec     cx
        jnz     INIT

        ;保存メモリの0クリア
        ;call    CLM
        ;グライダーガン + イーター
        ;call    GGUN
        ;銀河
        ;call GALAXY

        call    DISPLAY ;保存メモリの内容をVRAMに書き込む

        mov     cx, 100 ;ループの回数
LOOP:
        ;mov     bx, 1000
        ;call    SLEEP ;bxにsleepする長さ
        call    UPDATE
        call    DISPLAY
        dec     cx
        jnz     LOOP

        mov     ax, 0700h ;白背景黒文字NULL
        call    CLS ;axに埋め尽くす文字

        mov     ah, 00
        int     21h

;VRAMから近傍のセルの状態を確認し、保存メモリをアップデート
UPDATE  PROC    NEAR
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di

        mov     si, 0 ;VRAMのオフセット
        mov     di, 0 ;保存メモリのオフセット

        ;例外を判定してオフセットの配列を作成
CHECK:
        mov     bx, 7e0h ;オフセットの配列の先頭
        mov     WORD PTR es:[bx], -162
        mov     WORD PTR es:[bx+2], -160
        mov     WORD PTR es:[bx+4], -158
        mov     WORD PTR es:[bx+6], -2
        mov     WORD PTR es:[bx+8], 2
        mov     WORD PTR es:[bx+10], 158
        mov     WORD PTR es:[bx+12], 160
        mov     WORD PTR es:[bx+14], 162

        mov     cx, 0 ;近傍の合計カウンタの初期化
CKTOP:
        ;上端であるかの確認
        cmp     di, 79 ;diには対象の文字数
        ja      CKBTM
        mov     WORD PTR es:[bx], 3838
        mov     WORD PTR es:[bx+2], 3840
        mov     WORD PTR es:[bx+4], 3842
        jmp     CKLFT
CKBTM:
        ;下端であるかの確認
        cmp     di, 1920
        jb      CKLFT
        sub     WORD PTR es:[bx+10], 4000
        sub     WORD PTR es:[bx+12], 4000
        sub     WORD PTR es:[bx+14], 4000
CKLFT:
        ;左端であるかの確認
        push    bx
        mov     ax, di
        mov     dx, 0
        mov     bx, 80
        div     bx
        pop     bx
        cmp     dx, 0 ;割り切れていれば左端
        jnz     CKRGT
        add     WORD PTR es:[bx], 160
        add     WORD PTR es:[bx+6], 160
        add     WORD PTR es:[bx+10], 160
        jmp     COUNT
CKRGT:
        ;右端であるかの確認
        push    bx
        mov     ax, di
        mov     dx, 0
        mov     bx, 80
        div     bx
        pop     bx
        cmp     dx, 79 ;余り79で右端
        jne     COUNT
        sub     WORD PTR es:[bx+4], 160
        sub     WORD PTR es:[bx+8], 160
        sub     WORD PTR es:[bx+14], 160
COUNT:
        ;VRAMを参照して、「生」のセルをカウント
        push    si ;対象のオフセットアドレスを退避
        add     si, es:[bx] ;近傍のオフセットアドレスを加算
        add     cl, [si] ;VRAMを参照して状態を加算
        inc     bx ;オフセットアドレスの配列は
        inc     bx ;16bitごと
        pop     si ;対象のオフセットアドレスを取り出す
        cmp     bx, 7efh
        jb      COUNT

        jmp     CALC
JUMPP:
        jmp     CHECK

        ;カウンターの値によって保存メモリの値を更新
CALC:
        cmp     cl, 4 ;近傍が2個「生」の状態
        jb      DEAD ;2個以下は過疎
        jz      CALCEND ;2個は維持
        cmp     cl, 6 ;近傍が3個「生」の状態
        jz      ALIVE ;3個ちょうどは誕生、「生」維持
        jmp     DEAD ;3個以上は過密
ALIVE:
        mov     BYTE PTR es:[di], 2
        jmp     CALCEND
DEAD:
        mov     BYTE PTR es:[di], 0
        jmp     CALCEND
CALCEND:
        ;保存メモリのオフセットをインクリメント
        inc     di
        ;VRAMのオフセットをインクリメント*2
        inc     si
        inc     si
        ;全セル完了したら終了
        cmp     di,7d0h

        jne     JUMPP

        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
UPDATE  ENDP

;保存メモリのあたりをVRAMに書き込む
DISPLAY PROC    NEAR
        push    ax
        push    cx
        push    si
        push    di

        mov     cx, 7d0h ;全文字数
        mov     si, 0 ;VRAMのオフセット
        mov     di, 0 ;保存メモリのオフセット
DISP1:
        mov     ah, es:[di] ;保存メモリから値を取り出す
        inc     di
        mov     [si], ah ;VRAMに書き込む
        inc     si
        inc     si
        dec     cx
        jnz     DISP1

        pop     di
        pop     si
        pop     cx
        pop     ax
        ret
DISPLAY ENDP

;axに埋め尽くしたい文字を持たせて実行
CLS     PROC    NEAR
        push    cx
        push    si

        mov     si, 0
        mov     cx, 7d0h
CLS1:
        mov     [si], ax
        inc     si
        inc     si
        dec     cx
        jnz     CLS1

        pop     si
        pop     cx
        ret
CLS     ENDP

;bxにsleepする長さを持たせて実行
SLEEP   PROC    NEAR
        push    bx
        push    cx
SLEEP1:
        mov     cx, 0
SLEEP2:
        dec     cx
        jnz     SLEEP2
        dec     bx
        jnz     SLEEP1
        pop     cx
        pop     bx
        ret
SLEEP   ENDP

;axに最大値を入れて実行
;axに乱数値が入って終了
RND     PROC    NEAR
        push    bx
        push    dx

        mov     bx, ax
        mov     ax, es:[800h]
        mov     dx, 8405h
        mul     dx
        cmp     ax, es:[800h]
        jnz     GOTSEED
        inc     ax
GOTSEED:
        mov     es:[800h], ax
        mov     ax, dx
        xor     ah, al
        mov     dx, 0
        div     bx
        mov     ax, dx

        pop     dx
        pop     bx
        ret
RND     ENDP

;================================
; いろいろの形の初期設定
;================================
;VRAMの状態保存メモリの初期化
CLM     PROC    NEAR
        push    cx
        push    di

        mov     cx, 7d0h
        mov     di,0
CLMLOOP:
        mov     BYTE PTR es:[di], 0
        inc     di
        dec     cx
        jnz     CLMLOOP

        pop     di
        pop     cx
        ret
CLM     ENDP

;銀河
GALAXY  PROC    NEAR
        push    ax
        mov     ah, 2

        mov     es:[1189],ah
        mov     es:[1190],ah
        mov     es:[1191],ah
        mov     es:[1192],ah
        mov     es:[1193],ah
        mov     es:[1194],ah
        mov     es:[1196],ah
        mov     es:[1197],ah

        mov     es:[1269],ah
        mov     es:[1270],ah
        mov     es:[1271],ah
        mov     es:[1272],ah
        mov     es:[1273],ah
        mov     es:[1274],ah
        mov     es:[1276],ah
        mov     es:[1277],ah

        mov     es:[1356],ah
        mov     es:[1357],ah

        mov     es:[1429],ah
        mov     es:[1430],ah
        mov     es:[1436],ah
        mov     es:[1437],ah

        mov     es:[1509],ah
        mov     es:[1510],ah
        mov     es:[1516],ah
        mov     es:[1517],ah

        mov     es:[1589],ah
        mov     es:[1590],ah
        mov     es:[1596],ah
        mov     es:[1597],ah

        mov     es:[1669],ah
        mov     es:[1670],ah

        mov     es:[1749],ah
        mov     es:[1750],ah
        mov     es:[1752],ah
        mov     es:[1753],ah
        mov     es:[1754],ah
        mov     es:[1755],ah
        mov     es:[1756],ah
        mov     es:[1757],ah

        mov     es:[1829],ah
        mov     es:[1830],ah
        mov     es:[1832],ah
        mov     es:[1833],ah
        mov     es:[1834],ah
        mov     es:[1835],ah
        mov     es:[1836],ah
        mov     es:[1837],ah

        pop     ax
        ret
GALAXY  ENDP

;グライダーガン+イーター
GGUN    PROC    NEAR
        push    ax
        mov     ah, 2

        mov     es:[24],ah
        mov     es:[26],ah

        mov     es:[103],ah
        mov     es:[106],ah

        mov     es:[173],ah
        mov     es:[182],ah
        mov     es:[183],ah
        mov     es:[194],ah
        mov     es:[195],ah

        mov     es:[252],ah
        mov     es:[254],ah
        mov     es:[260],ah
        mov     es:[261],ah
        mov     es:[265],ah
        mov     es:[274],ah
        mov     es:[275],ah

        mov     es:[320],ah
        mov     es:[321],ah
        mov     es:[332],ah
        mov     es:[333],ah
        mov     es:[335],ah
        mov     es:[342],ah
        mov     es:[343],ah
        mov     es:[349],ah
        mov     es:[350],ah

        mov     es:[400],ah
        mov     es:[401],ah
        mov     es:[412],ah
        mov     es:[413],ah
        mov     es:[415],ah
        mov     es:[416],ah
        mov     es:[423],ah
        mov     es:[426],ah
        mov     es:[431],ah

        mov     es:[492],ah
        mov     es:[493],ah
        mov     es:[495],ah
        mov     es:[504],ah
        mov     es:[506],ah

        mov     es:[572],ah
        mov     es:[574],ah

        mov     es:[653],ah
        mov     es:[663],ah

        mov     es:[744],ah

        mov     es:[822],ah
        mov     es:[823],ah
        mov     es:[824],ah

        mov     es:[986],ah
        mov     es:[987],ah

        mov     es:[1066],ah
        mov     es:[1068],ah

        mov     es:[1148],ah

        mov     es:[1228],ah
        mov     es:[1229],ah

        pop     ax
        ret
GGUN    ENDP

CSEG    ENDS
END     START
