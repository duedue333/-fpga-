`timescale 1ns / 1ps

module control(
    input        clk,
    input        sw0,    
    input        sw11,  
    input        key0, key1, key2, key3,
    output reg [1:0] floor = 1,
    output reg       dir,    
    output reg       running,
    output reg [3:0] led,
    output reg [5:0] tim_4
    );

    localparam IDLE = 0;
    localparam MOVE_UP = 1;
    localparam MOVE_DOWN = 2;
    
    reg [2:0] state = IDLE;
    reg [3:0] req;
    reg [31:0] tmr;

    
    localparam RUNS = 5000000; //0.1s

    reg [3:0] req_clear; 
//按键响应
    always @(posedge clk) begin
        if (sw11) begin
       
            req <= 0;
       end else if (sw0) begin
       
            req <= 0;
        end else begin
            if (key0) req[0] <= 1;
            if (key1) req[1] <= 1;
            if (key2) req[2] <= 1;
            if (key3) req[3] <= 1;

            if (req_clear[0]) req[0] <= 0;
            if (req_clear[1]) req[1] <= 0;
            if (req_clear[2]) req[2] <= 0;
            if (req_clear[3]) req[3] <= 0;
        end
    end
//主状态机
reg bian_xiang = 0;

    always @(posedge clk) begin
        req_clear <= 0;
        if (sw11) begin//SW11空循环
        end 
     else if (sw0) begin//SW0强制复位
         
            if ((state == IDLE && floor == 2)|| state == MOVE_UP) begin
                if (state == MOVE_UP) begin
                    if(tim_4<30)begin//时间
                        state <= MOVE_DOWN;
                        dir <= 0;
                        tim_4 <= tim_4; //倒计时改为正
                        led <=0;
                    end
                    else begin
                        state <= MOVE_DOWN;
                        dir <= 0;
                        tim_4<= 0; 
                        running<=1;
                        led <=0;
                    end
                end 
                else if (state == IDLE && floor == 2) begin
                    state <= MOVE_DOWN;
                    dir <= 0;
                    running <= 1;
                    tmr <= 0;
                    tim_4<= 0;
                    led <= 0; 
                end
            end 
            else if (state == MOVE_DOWN) begin
                if (tmr >= RUNS - 1) begin
                    tmr <= 0;
                    if (tim_4 >= 30) begin
                        state <= IDLE;
                        floor <= 1;
                        running <= 0;
                        tim_4 <=0;
                    end 
                    else begin
                        tim_4 <= tim_4 + 1;
                    end
                    if (tim_4 >= 19) floor <= 1; else floor <= 2;
                end 
                else begin
                    tmr <= tmr + 1;
                end
            end 
            else begin
                state <= IDLE;
                floor <= 1;
                running <= 0;
                led <= 0;
            end
        end 
        else begin//正常运行
            case (state)
                IDLE: begin//待机状态
                    running <= 0;
                    tmr <= 0;
                    tim_4 <= 0;
                    if (floor == 1) begin
                        if (req[3] || req[1]) begin //上二楼
                            state <= MOVE_UP;
                            dir <= 1;
                            running <= 1;
                            if (req[3]) begin
                                led[3] <= 1;
                                req_clear[3] <= 1;
                            end 
                            else begin
                                led[1] <= 1;
                                req_clear[1] <= 1;
                            end
                        end
                        else if (req[0] || req[2])begin
                            req_clear[0]<=1;
                            req_clear[2]<=1;
                        end
                    end 
                    else begin 
                        if (req[2] || req[0]) begin //去一楼
                            state <= MOVE_DOWN;
                            dir <= 0;
                            running <= 1;
                            if (req[2]) begin
                                led[2] <= 1;
                                req_clear[2] <= 1;
                            end 
                            else begin
                                led[0] <= 1;
                                req_clear[0] <= 1;
                            end
                        end
                        else if (req[1] || req[3])begin
                            req_clear[1]<=1;
                            req_clear[3]<=1;
                        end
                    end
                end

                MOVE_UP: begin//上行状态
                    if (tmr >= RUNS - 1) begin
                        tmr <= 0;
                        if (tim_4 >= 29) begin//4s运行
                            floor <= 2;
                            led[1]<=0;
                            led[3]<=0;
                            running <= 0; 
                            tim_4 <= tim_4 + 1;
                            if(tim_4>=30)begin//1s下电梯
                                tim_4<=0;
                                if(bian_xiang == 1)begin//上行时有下行请求
                                    bian_xiang <= 0;
                                    state<=MOVE_DOWN;
                                    running<=1;
                                    dir<=0;
                                end
                                else begin
                                    state <= IDLE;
                                 end
                             end
                        end 
                        else begin
                            tim_4 <= tim_4 + 1;
                            if (tim_4 >= 19) floor <= 2; else floor <= 1;
                        end
                    end 
                    else begin
                        tmr <= tmr + 1;
                        if (req[2] || req[0]) begin//运行时按键响应
                            bian_xiang<=1;
                            if (req[2]) begin
                                led[2] <= 1;
                                req_clear[2] <= 1;
                            end 
                            else begin
                                led[0] <= 1;
                                req_clear[0] <= 1;
                            end
                        end
                        if (req[1] || req[3]) begin
                            if (req[1]) begin
                                led[1] <= 1;
                                req_clear[1] <= 1;
                            end 
                            else begin
                                led[3] <= 1;
                                req_clear[3] <= 1;
                            end
                        end
                    end
                end

                MOVE_DOWN: begin//下行状态
                    if (tmr >= RUNS - 1) begin
                        tmr <= 0;
                        if (tim_4 >= 29) begin//4s
                            floor <= 1;
                            led[2]<=0;
                            led[0]<=0;
                            running <= 0;
                            tim_4 <= tim_4 + 1;
                            if(tim_4>=30)begin//1s乘客下电梯
                                tim_4<=0;
                                if(bian_xiang==1)begin//如果返回
                                    bian_xiang<=0;
                                    running<=1;
                                    dir<=1;
                                    state<=MOVE_UP;
                                end
                                else begin
                                    state <= IDLE;
                                end
                           end
                        end 
                        else begin
                            tim_4 <= tim_4 + 1;
                            if (tim_4 >= 19) floor <= 1; else floor <= 2;
                        end
                   end 
                    else begin
                        tmr <= tmr + 1;
                        if (req[3] || req[1]) begin//运行时按键响应
                           bian_xiang<=1;
                           if (req[3]) begin
                               led[3] <= 1;
                               req_clear[3] <= 1;
                           end 
                           else begin
                               led[1] <= 1;
                               req_clear[1] <= 1;
                           end
                       end 
                       else if (req[2] || req[0]) begin
                          if (req[0]) begin
                              led[0] <= 1;
                              req_clear[0] <= 1;
                          end 
                          else begin
                              led[2] <= 1;
                              req_clear[2] <= 1;
                          end
                      end
                    end
                end
             default;
            endcase
        end
    end
endmodule
