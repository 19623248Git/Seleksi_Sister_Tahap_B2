       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKING.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "input.txt".
           SELECT ACC-FILE ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT TMP-FILE ASSIGN TO "temp.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT-FILE ASSIGN TO "output.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT INTS-FILE ASSIGN TO "interest.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT INTS-TEMP ASSIGN TO "int_temp.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD IN-FILE.
       01 IN-RECORD             PIC X(18).

       FD ACC-FILE.
       01 ACC-RECORD-RAW        PIC X(18).

       FD TMP-FILE.
       01 TMP-RECORD            PIC X(18).

       FD INTS-FILE.
       01 INTS-RECORD            PIC X(24).

       FD INTS-TEMP.
       01 ITEMP-RECORD       PIC X(24).

       FD OUT-FILE.
       01 OUT-RECORD            PIC X(69).

       WORKING-STORAGE SECTION.
       
       01 WS-UNIX-TIMESTAMP   PIC S9(18) COMP-5.
       77 WS-ARGUMENT           PIC X(80).
       77 TMP_TIMESTAMP         PIC X(18).
       77 INT_NOW               PIC 9(18).
       77 INT_THEN              PIC 9(18).
       77 DIFF_TIME             PIC 9(18).
       77 N_INT                 PIC 9(18).
       77  I                   PIC 9(18). *> Loop counter for interest
       77 IN-ACCOUNT            PIC 9(6).
       77 IN-ACTION             PIC X(3).
       77 IN-AMOUNT             PIC 9(6)V99.

       77 ACC-ACCOUNT           PIC 9(6).
       77 ACC-ACTION            PIC X(3).
       77 ACC-BALANCE           PIC 9(6)V99.

       77 TMP-BALANCE           PIC 9(6)V99.

       77 TMP-IDR-BALANCE       PIC X(15).
       77 TMP-IDR-BALANCE_NUM   PIC 9(15).
       77 MATCH-FOUND           PIC X VALUE "N".
       77 INT-FOUND             PIC X VALUE "N".
       77 UPDATED               PIC X VALUE "N".

       77 FORMATTED-AMOUNT      PIC 9(6).99.
       77 BALANCE-TEXT          PIC X(20).

       77 BALANCE-ALPHA         PIC X(15).

       PROCEDURE DIVISION.

       MAIN.
           ACCEPT WS-ARGUMENT FROM COMMAND-LINE
           PERFORM READ-INPUT
           PERFORM PROCESS-INTERESTS
           PERFORM PROCESS-RECORDS
           IF MATCH-FOUND = "N"
               IF IN-ACTION = "NEW"
                   PERFORM APPEND-ACCOUNT
                   PERFORM APPEND-INTEREST
                   MOVE "ACCOUNT CREATED" TO OUT-RECORD
               ELSE
                   MOVE "ACCOUNT NOT FOUND" TO OUT-RECORD
               END-IF
           END-IF
           PERFORM FINALIZE
           STOP RUN.

       READ-INPUT.
           OPEN INPUT IN-FILE
           READ IN-FILE AT END
               DISPLAY "NO INPUT"
               STOP RUN
           END-READ
           CLOSE IN-FILE

           MOVE IN-RECORD(1:6) TO IN-ACCOUNT
           MOVE IN-RECORD(7:3) TO IN-ACTION
           MOVE FUNCTION NUMVAL(IN-RECORD(10:9)) TO IN-AMOUNT.

       PROCESS-RECORDS.
           OPEN INPUT ACC-FILE
           OPEN OUTPUT TMP-FILE
           PERFORM UNTIL MATCH-FOUND = "Y"
               READ ACC-FILE
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       MOVE ACC-RECORD-RAW(1:6) TO ACC-ACCOUNT
                       MOVE FUNCTION NUMVAL(ACC-RECORD-RAW(10:9))
                           TO ACC-BALANCE
                       IF ACC-ACCOUNT = IN-ACCOUNT
                           MOVE "Y" TO MATCH-FOUND
                           PERFORM APPLY-ACTION
                       ELSE
                           WRITE TMP-RECORD FROM ACC-RECORD-RAW
                       END-IF
           END-PERFORM
           CLOSE ACC-FILE
           CLOSE TMP-FILE.

       PROCESS-INTERESTS.
           OPEN INPUT INTS-FILE
           OPEN OUTPUT INTS-TEMP
           PERFORM UNTIL INT-FOUND = "Y"
               READ INTS-FILE
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       MOVE INTS-RECORD(1:6) TO ACC-ACCOUNT
                       MOVE INTS-RECORD(7:18) TO INT_THEN
                       IF ACC-ACCOUNT = IN-ACCOUNT
                           MOVE "Y" TO INT-FOUND
                           DISPLAY INT-FOUND
                           PERFORM APPLY-INTEREST
                       ELSE
                           WRITE ITEMP-RECORD FROM INTS-RECORD
                       END-IF
           END-PERFORM
           CLOSE INTS-FILE
           CLOSE INTS-TEMP.

       APPLY-INTEREST.
           CALL "time" RETURNING WS-UNIX-TIMESTAMP
           MOVE WS-UNIX-TIMESTAMP TO TMP_TIMESTAMP
           DISPLAY "TIMESTAMP: " TMP_TIMESTAMP
           MOVE TMP_TIMESTAMP TO INT_NOW
           COMPUTE DIFF_TIME = INT_NOW - INT_THEN
           DISPLAY "TIME THEN: " INT_THEN
           DISPLAY "DIFFERENCE TIME: " DIFF_TIME
           COMPUTE N_INT = DIFF_TIME / 23
           MOVE IN-ACCOUNT TO ITEMP-RECORD(1:6)
           MOVE INT_NOW TO ITEMP-RECORD(7:18)
           WRITE ITEMP-RECORD.

       APPLY-ACTION.
           MOVE ACC-BALANCE TO TMP-BALANCE
           IF WS-ARGUMENT = "--apply-interest"
               IF INT-FOUND = "Y"
                   DISPLAY "BEFORE INTEREST: "
                       TMP-BALANCE
                   PERFORM VARYING I FROM 1 BY 1 UNTIL I > N_INT
                       COMPUTE TMP-BALANCE = TMP-BALANCE * 1.0005
                   END-PERFORM
                   DISPLAY "AFTER INTEREST: "
                       TMP-BALANCE  
               ELSE
                   DISPLAY "NO INTEREST RECORD"
              END-IF
           END-IF
           EVALUATE IN-ACTION
               WHEN "DEP"
                   IF IN-AMOUNT < ZERO
                       MOVE "INVALID DEPOSIT VALUE" TO OUT-RECORD
                   ELSE
                       IF IN-AMOUNT >= 999999.99
                           MOVE 999999.99 TO TMP-BALANCE
                           MOVE "CAPPED AT 999999.99" TO OUT-RECORD
                       ELSE
    
                           IF IN-AMOUNT > (999999.99 - TMP-BALANCE) 
                               MOVE 999999.99 TO TMP-BALANCE
                               DISPLAY "TMP-BALANCE: "TMP-BALANCE
                               MOVE "CAPPED AT 999999.99" TO OUT-RECORD
                           ELSE
                               ADD IN-AMOUNT TO TMP-BALANCE
                               MOVE "DEPOSITED MONEY" TO OUT-RECORD
                           END-IF
                       END-IF
                   END-IF
               WHEN "WDR"
                   IF IN-AMOUNT < ZERO
                       MOVE "INVALID WITHDRAWAL VALUE" TO OUT-RECORD
                   ELSE
                       IF IN-AMOUNT >= 999999.99
                           MOVE ZERO TO TMP-BALANCE
                           MOVE "CAPPED AT 000000.00" TO OUT-RECORD
                       ELSE

                           IF TMP-BALANCE < IN-AMOUNT
                               MOVE ZERO TO TMP-BALANCE
                               MOVE "CAPPED AT 000000.00" TO OUT-RECORD
                           ELSE
                               SUBTRACT IN-AMOUNT FROM TMP-BALANCE
                               MOVE "WITHDREW MONEY" TO OUT-RECORD
                           END-IF
                       END-IF
                   END-IF
               WHEN "BAL"
                   MOVE SPACES TO OUT-RECORD
                   MOVE "BALANCE (RAI): " TO BALANCE-TEXT
                   MOVE TMP-BALANCE TO FORMATTED-AMOUNT
                   MOVE FORMATTED-AMOUNT TO BALANCE-ALPHA
                   STRING BALANCE-TEXT DELIMITED SIZE
                          BALANCE-ALPHA DELIMITED SIZE
                          " | " DELIMITED BY SIZE
                          INTO OUT-RECORD
                   PERFORM CONVERT-IDR
                   MOVE "BALANCE (IDR): " TO BALANCE-TEXT
                   STRING OUT-RECORD DELIMITED BY "|"
                          BALANCE-TEXT DELIMITED SIZE
                          TMP-IDR-BALANCE DELIMITED SIZE
                          INTO OUT-RECORD
               WHEN OTHER
                   MOVE "UNKNOWN ACTION" TO OUT-RECORD
           END-EVALUATE

           MOVE IN-ACCOUNT TO TMP-RECORD(1:6)
           MOVE IN-ACTION  TO TMP-RECORD(7:3)
           MOVE TMP-BALANCE TO FORMATTED-AMOUNT
           MOVE FORMATTED-AMOUNT TO TMP-RECORD(10:9)

           WRITE TMP-RECORD
           MOVE "Y" TO UPDATED.

       APPEND-ACCOUNT.
           OPEN EXTEND ACC-FILE
           MOVE IN-ACCOUNT TO ACC-RECORD-RAW(1:6)
           MOVE IN-ACTION  TO ACC-RECORD-RAW(7:3)
           MOVE ZERO TO FORMATTED-AMOUNT
           MOVE FORMATTED-AMOUNT TO ACC-RECORD-RAW(10:9)

           WRITE ACC-RECORD-RAW
           CLOSE ACC-FILE.

       APPEND-INTEREST.
           OPEN EXTEND INTS-FILE
           CALL "time" RETURNING WS-UNIX-TIMESTAMP
           MOVE WS-UNIX-TIMESTAMP TO TMP_TIMESTAMP
           DISPLAY "TIMESTAMP: " TMP_TIMESTAMP
           MOVE TMP_TIMESTAMP TO INT_NOW
           MOVE IN-ACCOUNT TO ITEMP-RECORD(1:6)
           MOVE INT_NOW TO ITEMP-RECORD(7:18)

           WRITE ITEMP-RECORD
           CLOSE INTS-FILE.

       CONVERT-IDR.
           MOVE TMP-BALANCE TO FORMATTED-AMOUNT
           MOVE FORMATTED-AMOUNT TO TMP-IDR-BALANCE_NUM    
           MULTIPLY 16270 BY TMP-IDR-BALANCE_NUM
           MULTIPLY 7358 BY TMP-IDR-BALANCE_NUM
           MOVE TMP-IDR-BALANCE_NUM TO TMP-IDR-BALANCE.

       FINALIZE.
           IF UPDATED = "Y"
               CALL "SYSTEM" USING "mv temp.txt accounts.txt"
           END-IF
           IF INT-FOUND = "Y"
               CALL "SYSTEM" USING "mv int_temp.txt interest.txt"
           END-IF
           OPEN OUTPUT OUT-FILE
           WRITE OUT-RECORD
           CLOSE OUT-FILE.

