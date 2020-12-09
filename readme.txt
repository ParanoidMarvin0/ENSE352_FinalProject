readme.txt

ENSE 352 Final Project - Whack a Mole

Nolan Flegel
200250037
Dec 6, 2020

1. What is the game?
    This is an LED Whack a Mole game that uses 4 LEDs with 4 Buttons. 
    When an LED is lit up, the player must press the corresponding button within 
    the allotted time. A point is gained for each correct button press. The 
    game goes up to 15 points. Random LEDs will be lit following each press or 
    interval time expires. Each time a successful button is pressed, the interval
    time is decreased, making the game more difficult

2. How to play:
    i) A linear sequence of leds will flash while waiting for player to start the game  
    ii) Once the game has been started, a random LED will flash for a fixed period of time
        the player must press the corresponding button while the Led is lit to score a point
    iii) The game gets faster and faster with each correct button press
    iv) incorrect buttons do not end the game, however no score is recorded
    v) at the end of the round, the players score will be displayed in binary.

3. The biggest problem I encountered was time. This was a difficult semester with course load and 
    extenuating circumstances. I feel like I understand the material, however portions of this project were
    not fully implemented due to time constraints.

    I did not implement multiple rounds. I have some preliminary code written and commented out as debugging the
    additional logic required time that I did not have. 

    Future expansion would include additional game modes, like increase round length or variable time delays.

4. A) PrelimWait - Adjust the value in the variable WAIT_PLAYER_BLINK to increase or decrease the LED Blink interval
   B) ReactTime - The react time can be adjusted by changing the variable React_Timer
   C) The number of cycles can be adjusted by changing the value loaded into register R1 on line 248
   D) The values of WinningSignalTime and LosingSignalTime.  These cannot be adjusted as there is no corresponding 
        function in my game. The delay after a game ends can be adjusted by changing the variable SCORE_DISPLAY