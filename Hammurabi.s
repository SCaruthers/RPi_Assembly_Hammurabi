@ Hammurabi.s
@   re-written in ARM Assembly by S. Caruthers, 2020
@   Original in FOCAL by Doug Dyment, 1968
@   Later, rewritten in BASIC by David H. Ahl, 1971
@   And in a multitude of other languages by oh so many. 

@ -----------------------------------
@   Data Section
@ -----------------------------------

    .data
    .balign 4

@ Defined Constants:
.equ    FALSE,   0
.equ    TRUE,    0xFF
.equ    MAX_YRS, 10              @ Total number of years in reign


@ Global variables:

cur_year:   .int    0       @ counter for number of years
plague:     .int    FALSE   @ Flag for plague TRUE (0xFF) or FALSE (0)
population: .int    100     @ current total population
acre_cost:  .int    0       @ current price of land bushels / acre
acres_ownd: .int    1000    @ current acres owned
to_buy:     .int    0       @ how many acres to buy
to_sell:    .int    0       @ how many acres to sell 
to_feed:    .int    0       @ how many bushels to feed the people
to_plant:   .int    0       @ how many acres to plant
rats_ate:   .int    200     @ num bushels eaten by rats this year
num_deaths: .int    0       @ num people who starved this year
tot_deaths: .int    0       @ cumulative num of deaths, used for scoring
death_rate: .single 0       @ cumulative death rate, used for score
new_pop:    .int    5       @ number of births / immigrations this year 
hvest_tot:  .int    3000    @ total bushels harvested this year 
hvest_bpa:  .int    3       @ amount of harvest in bushels per acre 
storage:    .int    2800    @ total bushels in storage

@ Message Strings:
sformat:    .asciz "%u"         @ in scanf, we will take unsigned int
newline:    .asciz "\n"
welcom_msg: .ascii "\n\nCongratulations, you have been elected the ruler of ancient\n" 
            .ascii "Babylon. Your duties are to dispense food, direct farming,\n"
            .ascii "and buy and sell land as needed to support your people. Watch\n"
            .ascii "out for rat infestations and the plague! Grain is the general currency,\n"
            .ascii "measured in bushels. The following will help you in your decisions:\n"
            .ascii "\n"
            .ascii "  * Each person needs at least 20 bushels of grain per year to survive.\n"
            .ascii "  * Each person can farm at most 10 acres of land.\n"
            .ascii "  * It takes 1/2 bushel of grain to farm an acre of land\n"
            .ascii "  * The market price for land fluctuates yearly.\n\n"
            .ascii "Rule wisely and you will be showered with appreciation at the end of\n"
            .asciz "your term. Rule poorly and you will be kicked out of office!\n\n"
impeach_msg:.asciz "Due to this extreme mismanagement you have not only\nbeen impeached and thrown out of office, but you have\nalso been declared National Fink !!\n"
great_msg:  .asciz "A fantastic performance!!!  Charlemange, Disraeli, and \nJefferson combined could not have done better!\n"
so_so_msg:  .asciz "Your performance could have been somewhat better, but\nreally wasn\'t too bad at all. %u people would\ndearly like to see you assassinated but we all have our\ntrivial problems.\n"
bad_msg:    .asciz "Your heavy-handed performance smacks of Nero and Ivan IV.\nThe people (remaining) find you an unpleasant ruler, \nand, frankly, hate your guts!\n"
buy_prmp:   .asciz "How many acres of land do you want to buy? : "
buy_err1:   .asciz "Oh Great Hammurabi, we cannot buy any land this year, \nas we have too little grain.\n"
buy_err2:   .asciz "Oh Great Hammurabi, we do not have enough grain to buy %u acres.\n"
sell_prmp:  .asciz "How many acres of land do you want to sell? : "
sell_err1:  .asciz "Oh Great Hammurabi, we have no land to sell this year.\n"
sell_err2:  .asciz "Oh Great Hammurabi, we can sell only up to %u acres.\n"
feed_prmp:  .asciz "How much grain do you want to feed to the people? : "
feed_err1:  .asciz "Oh Great Hammurabi, we have no grain to feed the people!\n"
feed_err2:  .asciz "Oh Great Hammurabi, we do not have %u bushels to feed.\n"
starve_err: .asciz "You starved %u people in one year!!!\n"
plant_prmp: .asciz "How many acres do you want to plant? : "
plant_err1: .asciz "Oh Great Hammurabi, we have no grain to plant!\n"
plant_err2: .asciz "Oh Great Hammurabi, we own no land!!\n"
plant_err3: .asciz "Oh Great Hammurabi, we cannot plant so many acres!\n"
sum_msg1:   .asciz "\nO great Hammurabi!\nYou are in year %u of your 10 year rule.\n"
plague_msg: .asciz "There was a terrible plague and half the population died.\n"
sum_msg2:   .asciz "In the previous year, %u people starved to death,\nand %u people entered the kingdom.\nThe population is now %u.\n"
sum_msg3:   .asciz "We harvested %u bushels at %u bushels per acre.\n"
sum_msg4:   .asciz "Rats destroyed %u bushels, leaving %u bushels in storage.\n"
sum_msg5:   .asciz "The city owns %u acres of land.\nLand is currently worth %u bushels per acre.\n"
fnl_msg1:   .asciz "\nO Great Hammurabi!  Your reign is over.\n"
fnl_msg2:   .asciz "\nIn your 10-year reign, a total of %u people starved \nfor an average of %u%% per year.\n"
fnl_msg3:   .asciz "You started with 10 acres per person, and ended with %u.\n\n"
bye_msg:    .asciz "\nBye Bye, for now.\n"


@ -----------------------------------
@   Code Section
@ -----------------------------------

    .text
    .global main
    .extern printf          @ C-functions to be called
    .extern scanf           @ gcc will handle linking these 
    .extern rand


@ -----------------------------------
@   main: setup things, then loop through years of reign

main:   
        @ use r5 for current bushels in storage
        @ use r7 for current acres owned
        @ Setup things first and print welcome message
        push    {ip, lr}            @ push return address and dummy for alignment

        bl      seedRandom          @ call the function to seed random number

        ldr     r0, =welcom_msg     @ point to welcome message location
        bl      printf              @ call printf to print welcome message

    year_loop:
        ldr     r1, =cur_year       @ point to address of year counter
        ldr     r0, [r1]            @ get value of counter
        add     r0, r0, #1          @ r0 <- cur year + 1
        str     r0, [r1]            @ save value
    
        cmp     r0, #MAX_YRS        @ check if we are at MAX
        bgt     end_game            @ if cur > max, jump to end
        
        bl      getLandPrice        @ call subroutine for random land price

        bl      printSummary        @ call subroutine to print summary
        
        @ get grain in storage and acres owned into local variables, r5 & r7, repsectively
        ldr     r5, =storage
        ldr     r5, [r5]            @ r5 <- bushels in storage
        ldr     r7, =acres_ownd     
        ldr     r7, [r7]            @ r7 <- acres owned
        
        @ set yearly values to zero (do not carry over from previous year)
        mov     r0, #0              @ put 0 in r0, to zero out...
        ldr     r1, =to_buy         
        str     r0, [r1]            @ ...to_buy
        ldr     r1, =to_sell
        str     r0, [r1]            @ ...to_sell
        ldr     r1, =to_feed 
        str     r0, [r1]            @ ...to_feed
        ldr     r1, =to_plant       
        str     r0, [r1]            @ ...to_plant

    skip_to_buy:
        @ if there is any grain in storage, ask about buying land
        @ put number of acres to buy in r4
        cmp     r5, #17             @ if bushels in storage > 17 (cheapest land)
        bgt     prompt_to_buy       @   then skip to buying option  
                                    @ else, r5<17, so no grain to buy land with
        ldr     r0, =buy_err1       @   point to error message string
        bl      printf
        bal     skip_to_sell        @   move on to selling land
    prompt_to_buy:
        ldr     r0, =buy_prmp       @ point to prompt for buying land
        bl      printf  
        ldr     r0, =sformat        @ point to format for scanf 
        ldr     r1, =to_buy         @ point to location to store value
        bl      scanf               @ get user input (NOTE: failure if a character is entered!)
        ldr     r1, =to_buy         @ point to location of answer
        ldr     r6, [r1]            @ put user input into r6            
        cmp     r6, #1              @ if user buys 0 (or neg), then jump to sell 
        blt     skip_to_sell
        ldr     r3, =acre_cost      @ else, 
        ldr     r3, [r3]            @   put cost of land into r3
        mul     r4, r6, r3          @   calc cost (r4) = acres to buy * cost/acre
        cmp     r4, r5              @   cmp cost (r4) to bushels in storage (r5)
        blt     finish_buying       @   if cost < storage, go to complete
        mov     r1, r6              @     else, print error and loop
        ldr     r0, =buy_err2       @     with r1=#acres to buy as param
        bl      printf              @     to printf
        bal     prompt_to_buy       @     Go ask again until valid entry
    finish_buying:                  @ if we got here, acres to buy >= 1 and valid
        sub     r5, r5, r4          @ Reduce grain in storage (r5) by cost (r4)
        add     r7, r7, r6          @ Inc acres_ownd (r7) by acres bought (r6)
        bal     feed_them           @ If we bought, skip the selling

    skip_to_sell:
        cmp     r7, #0              @ is acres owned > 0?
        bgt     prompt_to_sell      @   then branch to selling
        ldr     r0, =sell_err1      @   else, print error message
        bl      printf              
        bal     feed_them           @   and branch to next topic
    prompt_to_sell:
        ldr     r0, =sell_prmp      @ point to prompt message string
        bl      printf
        ldr     r0, =sformat        @ point to format for scanf 
        ldr     r1, =to_sell        @ point to location to store value
        bl      scanf               @ get user input (NOTE: failure if a character is entered!)
        ldr     r1, =to_sell        @ point to location of answer
        ldr     r6, [r1]            @ put user input into r6            
        cmp     r6, #1              @ if user sells 0 (or neg), then jump to next topic 
        blt     feed_them
        cmp     r6, r7              @ is acres owned >= acres to sell?
        ble     finish_selling      @ if so, branch to finish selling
        mov     r1, r7              @   else, print error message with
        ldr     r0, =sell_err2      @   r1=# acres owned as parameter
        bl      printf              @   to printf
        bal     prompt_to_sell      @   Go ask again until valid entry
    finish_selling:                 @ if we got here, acres to sell >=1 and valid
        ldr     r3, =acre_cost      @ figure out sale proceeds 
        ldr     r3, [r3]            @ put cost of land into r3
        mul     r4, r6, r3          @ calc cost (r4) = acres to sell * cost/acre
        add     r5, r5, r4          @ Inc grain in storage (r5) by cost (r4)
        sub     r7, r7, r6          @ Dec acres_ownd (r7) by acres sold (r6)

    feed_them:
        cmp     r5, #0              @ do we have grain to feed?
        bgt     prompt_to_feed      @   then skip to feeding
        ldr     r0, =feed_err1      @   else, print error message 
        bl      printf
        bal     plant_it            @   and branch to next topic
    prompt_to_feed:
        ldr     r0, =feed_prmp      @ point to prompt message string
        bl      printf
        ldr     r0, =sformat        @ point to format for scanf 
        ldr     r1, =to_feed        @ point to location to store value
        bl      scanf               @ get user input (NOTE: failure if a character is entered!)
        ldr     r1, =to_feed        @ point to location of answer
        ldr     r6, [r1]            @ put user input into r6            
        cmp     r6, #1              @ if user feeds 0 (or neg), then jump to next topic 
        movlt   r6, #0              @   but first force to_feed == 0 in case user input neg
        strlt   r6, [r1]            
        blt     plant_it            @   and branch to next topic
        cmp     r6, r5              @ compare bushels to feed with storage
        ble     finish_feeding      @ if feed <= storage, branch to finish feeding
        mov     r1, r6              @   else, print error message with
        ldr     r0, =feed_err2      @   number to feed as parameter
        bl      printf              @   to printf
        bal     prompt_to_feed      @   Go ask again until valid entry
    finish_feeding:
        sub     r5, r5, r6          @ Reduce stored grain by amount fed
                                    @ Deal with starvation later
                                    
    plant_it:
        cmp     r5, #0              @ do we have grain to plant?
        bgt     check_acres         @   then skip error
        ldr     r0, =plant_err1     @ else, print error message
        bl      printf        
        bal     update_population   @ and branch to next topic
    check_acres:
        cmp     r7, #0              @ do we have any acreage to plant?
        bgt     prompt_to_plant     @   then skip to it
        ldr     r0, =plant_err2     @ else, print error message
        bl      printf  
        bal     update_population   @ and branch to next topic
    prompt_to_plant:
        ldr     r0, =plant_prmp     @ point to prompt message string
        bl      printf
        ldr     r0, =sformat        @ point to format for scanf 
        ldr     r1, =to_plant       @ point to location to store value
        bl      scanf               @ get user input (NOTE: failure if a character is entered!)
        ldr     r1, =to_plant       @ point to location of answer
        ldr     r6, [r1]            @ put user input into r6            
        cmp     r6, #1              @ if user plants 0 (or neg), then jump to next topic 
        movlt   r6, #0              @   but first force to_plant == 0 in case user input neg
        strlt   r6, [r1]            
        blt     update_population   @   and branch to next topic
                                    @ else, continue and check seed, people, acres
        mov     r0, r6, LSR#1       @ how many bushels required to plant = to_plant / 2
        ldr     r1, =population     @ get population to calculate total acres that can be planted
        ldr     r1, [r1]
        mov     r2, #10             
        mul     r1, r1, r2          @ which is 10 acres per person 
        cmp     r6, r7              @ compare if acres to plant (r6) <= acres owned (r7)
        cmple   r0, r5              @ or if seed required (r0) <= storage (r5)
        cmple   r6, r1              @ or if acres to plant (r6) <= what population can plant (r1)
        ble     finish_planting     @ then skip over the error message
        ldr     r0, =plant_err3     @ else, print err message
        bl      printf
        bal     prompt_to_plant     @ and go back to ask again.
    finish_planting:
        sub     r5, r5, r0          @ reduce stored grain by amount planted


    update_population:
        bl      updatePopulation    @ call subroutine, returns success in r0
        cmp     r0, #FALSE          @ if update returns FALSE, impeach! (and end game)
        bne     update_harvest      @ otherwise, skip to next topic
        ldr     r0, =starve_err     @   point to error message
        ldr     r1, =num_deaths     @   point to number of deaths
        ldr     r1, [r1]            @   put in r1 for printf
        bl      printf              @   print starvation message.
        ldr     r0, =impeach_msg    @   point to impeachment message
        bl      printf
        bal     end_main            @   goto end of program
    
    update_harvest:
        ldr     r1, =storage        @ before going to subroutine, 
        str     r5, [r1]            @ update global storage with local (r5)
        bl      updateHarvest       @ call subroutine, returns nothing
                                    @ but harvest-related globals are updated
        
    update_globals:
        @ update remaining globals.
        ldr     r1, =acres_ownd      
        str     r7, [r1]            @ put updated value in global acres_ownd
        
        bal     year_loop           @ loop to next year
    
    end_game:
        bl      printScore          @ print Score Summary and message 
        
    end_main:        
        ldr     r0, =bye_msg
        bl      printf
    
        pop     {ip, pc}            @ return to OS by loading lr into pc


@ -----------------------------------
@   Code Section -- Subroutines
@ -----------------------------------

@ -----------------------------------
@   seedRandom(): seed the rand number generator
seedRandom:
        @ seed the random number generator
        @ based on the time as a seed.
        push    {r0, r1, lr}    @ protect r0 and r1
        mov     r0, #0
        bl      time            @ get the time into r0
        mov     r1, r0          @ put time in r1 to pass as param
        bl      srand           @ call c-function srand()
        pop     {r0, r1, pc}    @ return


@ -----------------------------------
@   rando(r0): return a random number
rando:
        @ return a random number in r0
        @ ranging from 0 to [r0]-1 when called (r0 transfered r4)
        @ To save time, limit to <= 0xFFFF
        push    {r4, r5, lr}    @ protect r4, r5
        mov     r4, r0          @ put r0 into r4 because r0 gets destroyed
        mov     r0, #0
        bl      rand 
        mov     r5, #0xFF00
        orr     r5, r5, #0xFF   @ make r5 = 0xFFFF
        and     r0, r0, r5      @ limit result to lower 2 bytes to save time
        cmp     r0, r4
        blt     r_done          @ if result < limit, then we are done
    r_loop:
        subs    r0, r0, r4      @   keep subtracting r4 until we can no longer
        cmp     r0, r4
        bge     r_loop          @   gives r0 % r4 (remainder) which ranges 0 < r4
    r_done:
        pop     {r4, r5, pc}    @ return

@ -----------------------------------
@   intDivde(r0, r1): returns int of floor( r0 / r1 )
intDivide:
        @ Uses FPU to calculate the result of floor(r0/r1)
        @ Warning: does not check for divide by zero!!
        @ Assumes r0 and r1 hold valid values
        
        push    {lr}
        
        vmov    s14, r0         @ move r0 into FP register s14
        vmov    s15, r1         @ move r1 into s15
        
        vdiv.F32 s16, s14, s15  @ perform division on FPU
        vcvt.U32.F32  s16, s16  @ convert FP to Int by rounding toward 0
                                @ could use R flag to round per fpscr
        
        vmov    r0, s16         @ put result in r0 to return 
        pop     {pc}            @ and return

@ -----------------------------------
@   printSummary(): prints the summary of this years events
printSummary:
        @ returns nothing, protects all registers used
        @ Prints the summary which includes, e.g.:
        @   O great Hammurabi!
        @   You are in year 1 of your 10 year rule.
        @   In the previous year, 0 people starved to death,
        @   and 5 people entered the kingdom.
        @   The population is now 100.
        @   We harvested 3000 bushels at 3 bushels per acre.
        @   Rats destroyed 200 bushels, leaving 2800 bushels in storage.
        @   The city owns 1000 acres of land.
        @   Land is currently worth 20 bushels per acre.

        push    {r0-r4, lr}         @ protect registers and store return link
        
        @ print 1st line with year of reign
        ldr     r1, =cur_year       @ point to address of year counter
        ldr     r1, [r1]            @ get value of counter into r1 for printf
        ldr     r0, =sum_msg1       @ point to 1st line of summary message 
        bl      printf
        @ print if there was a plague, if there was one
        ldr     r1, =plague         @ point to location of plague flag
        ldr     r1, [r1]            @ and put value in r1
        cmp     r1, #FALSE          @ was there a plague?
        beq     no_plague           @ if not, skip printing
        ldr     r0, =plague_msg     @ point to location of plague string
        bl      printf
    no_plague:
        @ print the # deaths (r1), # births/immigrants (r2), and current population (r3)
        ldr     r1, =num_deaths     @ point to location of number of deaths
        ldr     r1, [r1]            @ and put value in r1
        ldr     r2, =new_pop        @ point to location of number of new population
        ldr     r2, [r2]            @ and put value in r2
        ldr     r3, =population     @ point ot location of population
        ldr     r3, [r3]            @ and put value in r3
        ldr     r0, =sum_msg2       @ point to population line of summary message
        bl      printf
        
        @ print harvest information: 
        @   total (r1), rate (r2), then rat eaten (r1), storage (r2)
        ldr     r1, =hvest_tot
        ldr     r1, [r1]
        ldr     r2, =hvest_bpa
        ldr     r2, [r2]
        ldr     r0, =sum_msg3
        bl      printf
        ldr     r1, =rats_ate
        ldr     r1, [r1]
        ldr     r2, =storage
        ldr     r2, [r2]
        ldr     r0, =sum_msg4
        bl      printf
        
        @ print property report including total owned (r1) and price (r2)
        ldr     r1, =acres_ownd
        ldr     r1, [r1]
        ldr     r2, =acre_cost
        ldr     r2, [r2]
        ldr     r0, =sum_msg5
        bl      printf
        
    end_printSummary:    
        pop     {r0-r4, pc}         @ return 

@ -----------------------------------
@   printScore(): prints score summary and message
printScore:
        @ returns nothing
        @ prints final summary, score and message
        @ depending on death rate and land ownership
        
        push    {r4-r6, lr}         @ save return link
        
        @ print 1st line with last year of reign
        ldr     r0, =fnl_msg1       @ point to 1st line of message 
        bl      printf
        @ print if there was a plague, if there was one
        ldr     r1, =plague         @ point to location of plague flag
        ldr     r1, [r1]            @ and put value in r1
        cmp     r1, #FALSE          @ was there a plague?
        beq     no_plague2          @ if not, skip printing
        ldr     r0, =plague_msg     @ point to location of plague string
        bl      printf
    no_plague2:
        @ print the # deaths (r1), # births/immigrants (r2), and current population (r3)
        ldr     r1, =num_deaths     @ point to location of number of deaths
        ldr     r1, [r1]            @ and put value in r1
        ldr     r2, =new_pop        @ point to location of number of new population
        ldr     r2, [r2]            @ and put value in r2
        ldr     r3, =population     @ point ot location of population
        ldr     r3, [r3]            @ and put value in r3
        ldr     r0, =sum_msg2       @ point to population line of summary message
        bl      printf
        
        @ print the average death rate (r2) and total starvations (r1)
        ldr     r2, =death_rate
        vldr    s0, [r2]
        vcvt.U32.F32 s0, s0         @ convert single to int (for easy print and cmp)
        vmov    r2, s0              @ r2 <- death rate (as int) for printf
        mov     r5, r2              @ r5 <- death rate (for later)
        ldr     r1, =tot_deaths
        ldr     r1, [r1]
        ldr     r0, =fnl_msg2
        bl      printf
        
        @ calculate acres / person as part of scoring
        ldr     r0, =acres_ownd
        ldr     r0, [r0]            @ r0 <- num acres owned
        ldr     r1, =population     @ r1 <- final population
        ldr     r1, [r1]
        bl      intDivide           @ caluculate acres/pop
        mov     r6, r0              @ r6 <- acres/pop (for later)
        mov     r1, r0              @ also for printf
        ldr     r0, =fnl_msg3       @ point to 3rd message
        bl      printf              
        
        @ now figure out which message to say.  Based on:
        @   r5 <- death rate
        @   r6 <- acres per person
        @   r5 > 33 or r6 < 7  : impeach
        @   r5 > 10 or r6 < 9  : bad
        @   r5 > 3  or r6 < 10 : so-so
        @   else               : great
        
        @ impeach
        cmp     r5, #33             @ is r5 > 33
        ldrgt   r0, =impeach_msg    @   then done. point to message
        bgt     print_saying        @   and go print it
        cmp     r6, #7              @ else, is r6 < 7
        ldrlt   r0, =impeach_msg    @   then point to message
        blt     print_saying        @   and go print it
        
        @ else, bad
        cmp     r5, #10             @ is r5 > 10
        ldrgt   r0, =bad_msg        @   then done. point to message
        bgt     print_saying        @   and go print it
        cmp     r6, #9              @ else, is r6 < 9
        ldrlt   r0, =bad_msg        @   then point to message
        blt     print_saying        @   and go print it

        @ else, so-so
        mov     r0, #11             @ Need a random number for this message
        bl      rando              
        add     r1, r0, #2          @ make r1 from 2 to 12
        cmp     r5, #3              @ is r5 > 3
        ldrgt   r0, =so_so_msg      @   then done. point to message
        bgt     print_saying        @   and go print it
        cmp     r6, #10             @ else, is r6 < 10
        ldrlt   r0, =so_so_msg      @   then point to message
        blt     print_saying        @   and go print it
        
        @ else, great
        ldr     r0, =great_msg      @ if none of the others, then great!
        
    print_saying:
        bl      printf
        
        pop     {r4-r6, pc}         @ return
@ -----------------------------------
@   getLandPrice(): put a random value between 17-26 into acre_cost
getLandPrice:
        @ returns nothing
        @ calls rando(10) to get random value 0-9 
        @ adds 17 to get value between 17-26
        @ and put it into acre_cost
        
        push    {r0, r1, lr}
        mov     r0, #10
        bl      rando
        add     r0, r0, #17
        ldr     r1, =acre_cost
        str     r0, [r1]
        pop     {r0, r1, pc}
        
@ -----------------------------------
@   isPlague(): randomly set flag TRUE or FALSE
isPlague:
        @ returns result in r0 
        @ sets global variable plague flag true 15% of the time
        @ note: use r4 instead of r1, becuase rando() clobbers r1
        
        push    {r4, lr}
        ldr     r4, =plague     @ put plague flag pointer into r4
        mov     r0, #FALSE      @ r0 <- FALSE
        str     r0, [r4]        @ for now, set flag FALSE
        mov     r0, #100        @ get a random number 0-99
        bl      rando           @ via rando(r0)
        cmp     r0, #15         @ if < 15 (out of 100), ie 15% of the time
        movlt   r0, #TRUE       @   then r0 <- TRUE
        strlt   r0, [r4]        @   and set flag TRUE   
        pop     {r4, pc}        @ return

@ -----------------------------------
@   updatePopulation(): returns TRUE or FALSE and updates global variable
updatePopulation:
        @ returns message in r0, 
        @    TRUE if people were fed 'enough'
        @    FALSE if too many (>50%) people starved and ruler should be impeached
        @ updates global population variable with new population:
        @    Incorporates plague, starvations, and births+immigration
        
        push    {r4-r7, lr}         @ protect the registers and store return link
        ldr     r4, =population     @ r4 points to current population global variable
        ldr     r6, [r4]            @ put population value in r6
        
        @ adjust for plague
        bl      isPlague            @ set flag for plague or not, return result in r0
        cmp     r0, #TRUE           @ if there was a plague,
        lsreq   r6, r6, #1          @ divide population by 2   
        
        @ adjust based on feeding 20 per person
        @   NOTE: Original game rule required 20 per person, 
        @   but changed here to make division easy!
        ldr     r0, =to_feed        @ How much grain was fed?
        ldr     r0, [r0]     
        mov     r3, #20       
        mul     r1, r6, r3          @ How much grain was required, ie., pop * 20
        subs    r2, r1, r0          @ r2 <- required - fed (setting flags)
        bmi     sufficient          @ if negative, fed plenty, skip to it.  else, 
        mov     r0, r2              @   r0 <- r2, i.e. (required - fed)
        mov     r1, #20             @   r1 <- 20 (to divide)
        bl      intDivide           @   returns r0 <- floor(r0 / r1)
        mov     r2, r0              @   r2 <- deficit / 20 : i.e., number of people starved
        
        @ check too many people (50%) starved, and impeach immediately if so
        @ Note: The original game used 45% as threshold. Here we used 50% since div by 2 is easier!
        mov     r3, r6, LSR#1       @   r3 <- current pop / 2 
        sub     r6, r6, r2          @   reduce population by # starved (r2)
        cmp     r2, r3              @   if r2 > r3, starved too many, so impeach
        movge   r0, #FALSE          @   set r0 to FALSE so to impeach and return
        bge     end_updatePopulation   
        bal     immigration         @ jump to next topic of population update

    sufficient:
        @ set num starvations = 0 and move on
        mov     r2, #0              @ r2 <- 0, no starvations this year 
        
    immigration:
        @ before doing immigration & births, update starvation rate for scoring
        mov     r0, r2              @ pass # starvations this year
        mov     r1, r6              @ current population
        bl      calcDeathRate
        
        @ calculate addition to population as 1 + ((20 * acres_ownd + storage) / (100 * population))
        
        ldr     r0, =acres_ownd     @ point to location with num acres_ownd
        ldr     r0, [r0]            @ and load it into r0 for start of numerator
        mov     r3, #20             @ put 20 into r3 for multiplication
        mul     r0, r0, r3          @ multiply r0 by 20
        ldr     r1, =storage        @ point to location with grain in storage
        ldr     r1, [r1]            @ put it in r1, to...
        add     r0, r0, r1          @ add storage to r0.
        mov     r3, #100            @ put 100 into r3 for multiplication
        mul     r1, r6, r3          @ r1 <- denominator = 100 * population
        bl      intDivide           @ returns int (r0 / r1)
        add     r0, r0, #1          @ add 1 for final answer
        
        ldr     r1, =new_pop        @ point to number of new people in the city this year 
        cmp     r2, #0              @ did any one starve?  If r2 > 0, someone starved, so no new population
        movgt   r0, #0              @ if any one starved, forget the calc and set to zero, otherwise
        str     r0, [r1]            @ store number of new people in that global variable, and
        add     r6, r6, r0          @ add new pop to population.

        mov     r0, #TRUE           @ set r0 to return TRUE, so as not to impeach
    end_updatePopulation:
        str     r6, [r4]            @ update global variable with new population
        ldr     r4, =num_deaths     @ point to global var with num deaths this year_loop
        str     r2, [r4]            @ update it with number of starvations
        ldr     r4, =tot_deaths     @ also add to global of total number of starvations
        ldr     r1, [r4]            
        add     r1, r1, r2          @ add current starvation to running total
        str     r1, [r4] 
        pop     {r4-r7, pc}         @ return

@ -----------------------------------
@   calcDeathRate(r0,r1): returns nothing, but updates global variable
calcDeathRate:
        @ assumes registers are passed as
        @   r0 = r2 <- current year num_deaths by starvation
        @   r1 = r6 <- population (already adjusted for starvation)
        
        push    {r2, r6, lr}
        
        mov     r2, r0              @ number of deaths by starvation
        mov     r6, r1              @ current total population (- curr deaths)
        add     r6, r6, r2          @ total pop before deaths subtracted

    
        @ new death_rate = (years_ruled * death_rate + 100 * num_deaths/population) / (years_ruled+1)
        mov     r3, #100            @ put 100 in r3 to multiply
        mul     r0, r2, r3          @ r0 <- (100 * num_deaths)
        vmov    s0, r0              @ put r0 into single float FPU register s0
        vcvt.f32.u32 s0, s0         @ convert from int to float
        vmov    s1, r6              @ similarly, s1 <- population
        vcvt.f32.u32 s1, s1         @ convert from int to float
        vdiv.f32 s0, s0, s1         @ s0 <- (100*num_deaths/population)
        ldr     r1, =death_rate     @ get current death rate
        vldr    s1, [r1]            @ s1 <- current death rate
        ldr     r1, =cur_year       @ get current year of rule (# years +1)
        ldr     r1, [r1]            @ put into r1 and
        sub     r1, r1, #1          @ dec by 1 to num years ruled
        vmov    s3, r1              @ into s3
        vcvt.f32.u32 s3, s3         @ convert from int to float
        vmul.f32 s1, s1, s3         @ s1 <- (death_rate * years_ruled)
        vadd.f32 s0, s0, s1         @ s0 <- (100 * num_deaths/population) + (death_rate * years_ruled)
        add     r1, r1, #1          @ (years_ruled+1)
        vmov     s3, r1             @ s3 <- (years_ruled+1)
        vcvt.f32.u32 s3, s3         @ convert from int to float
        vdiv.f32 s0, s0, s3         @ s0 <- new death_rate
        ldr     r1, =death_rate     
        vstr    s0, [r1]            @ update global variable of death_rate
    
        pop     {r2, r6, pc}

@ -----------------------------------
@   updateHarvest(): returns nothing, but updates global variable
updateHarvest:
        @ Returns nothing 
        @ Sets global variables related to harvest and rats eating it
        @ (so r5, storage, must be updated upon return)
        @ Relies on global variables (esp acres planted) being current.
        @ Harvest can range from 1 to 8 bushels per acre planted
        @ Rat infestations happen randomly at 40% of the time, and when it happens,
        @ they eat anywhere from 1/10 to 3/10 of the grain stores.
        
        push    {r4-r7, lr}         @ protect the registers and store return link
        
        mov     r0, #8              @ set r0 to pass to rando(r0)
        bl      rando               @ returns random number between 0 and r0-1
        add     r0, r0, #1          @ add 1 to make r0 range from 1 to 8
        
        ldr     r1, =to_plant       @ point to variable with acres planted
        ldr     r1, [r1]            @ put value into r1
        
        mul     r4, r0, r1          @ r4 <- Gross Harvest = yield * acres planted (r0 * r1)
        
        ldr     r1, =hvest_bpa      @ point to global for harvest yield rate
        str     r0, [r1]            @ put harvest yield into global variable
        ldr     r1, =hvest_tot      @ point to global for harvet total yield
        str     r4, [r1]            @ put gross Harvest into global variable
        ldr     r1, =storage        @ point to global for bushels in storage
        ldr     r1, [r1]            @ put value into r1
        add     r4, r1, r4          @ Add the harvest to the storage, put result in r4
        
        @ was there a rat infestation?
        ldr     r6, =rats_ate
        mov     r0, #0
        str     r0, [r6]            @ set rats_ate to zero
        mov     r0, #100
        bl      rando               @ return r0 <- value from 0 - 99
        cmp     r0, #40             @ should happen 40% of the time
        bgt     end_updateHarvest   @ if no infestation, skip to end
        mov     r0, #3              @ else,
        bl      rando               @   return r0 <- value 0 - 2
        add     r0, r0, #1          @   add 1 to get 1 - 3 (for 1/10 to 3/10)
        mul     r0, r4, r0          @   mul storage by the random number, then...
        mov     r1, #10             @   get ready to divide by 10
        bl      intDivide           @   r0 <- answer of how much rats ate
        str     r0, [r6]            @   put it in global variable, and 
        sub     r4, r4, r0          @   subtract it from storage, then

    end_updateHarvest:
        ldr     r1, =storage
        str     r4, [r1]            @ update global variable
        pop     {r4-r7, lr}         @ return 
