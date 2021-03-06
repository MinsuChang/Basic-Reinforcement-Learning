clear all; close all; clc;
global row col start goal wind gamma alpha epsilon N_Episode episodeCount ...
    Monitoring_SW

Monitoring_SW = 0; % Off: 0, ON : 1
%% Initialization
% Size of grid world
row = 4;
col = 12;

% Start and End Point
start.row = 4;
start.col = 1;
start;

goal.row = 4;
goal.col = 12;
goal;

% Wind
wind = [0 0 0 0 0 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 0 0 0 0;
    0 1 1 1 1 1 1 1 1 1 1 1 0;];

% RL parameter
gamma = 0.5;
alpha = 0.5;
epsilon = 0.01;
episodeCount= 800;
N_decision = 4;
N_Episode = 10000;

% Reward
rewardhold = -1;
rewardpos = 10;
rewardneg = -100;

% Variables
Q= zeros(row,col,4);
newQ= ones(row,col,4) * inf; %for convergence
temp= zeros(row,col,N_decision); %temp array for printing purpose
step_save = zeros(1,1);
Reward_save = zeros(1,1);
Rewardsum = 0;
action=0;
iteration = 1;
rewardVector= zeros(1,N_Episode);

if Monitoring_SW == 1
    figure('color','w');
end
%% Start
for count = 1:N_Episode
    current=start;
    step = 1;
    randN = 0 + (rand(1) * 1); % generating random double between 0 and 1
    
    if(randN > epsilon) %greedy
        [maxQ,action] = max(Q(current.row,current.col,:)); %get next pos
    else
        action = round(1 + (rand(1) * 3)); %random integer between 1 and 4
    end
    
    next = start;
    
    % For monitoring
    if Monitoring_SW == 1
        hold off;
        CreateGrid(row,col,start,goal); hold on;
    end
    % Loop for each steps of Episode
    while (isOverlap(current,goal) ~= 0 ) % until goal is reached
        if (step > episodeCount) %limited steps
            break;
        end
        [next, temp] = getNext(current, action, wind,temp, row, col);
        
        if isOverlap(next,goal) ~= 0
            reward = rewardhold;
            if next.row == row && next.col >= 2 && next.col < col, % Cliff
                reward = rewardneg;
                next = start;
            end
        else
            reward = rewardpos;
        end
        
        
        % Episilon-greedy
        randN = 0 + (rand(1) * 1);
        if(randN > epsilon)
            [~,nextAction] = max(Q(next.row,next.col,:));
        else
            nextAction = round(1 + (rand(1) * 3)); %random integer between 1 and 4
        end
        
        nextQ = Q(next.row,next.col,nextAction);
        currentQ = Q(current.row, current.col, action);
        Q(current.row, current.col, action) = currentQ + alpha* (reward + gamma*nextQ - currentQ);
        
        % Monitoring for each step
        if Monitoring_SW == 1
            setPoint(current.row, current.col, row,col);
            title(sprintf('Artificial intelligence\n Reinforcement learning\nStep = %d, Iteration = %d, Reward = %d', step, iteration, Rewardsum));
            drawnow;
        end
        
        rewardVector(1,iteration) = reward;
        Rewardsum = Rewardsum + reward;
        current = next;
        action = nextAction;
        step = step + 1;
    end
    
    step_save(iteration) = step;
    Reward_save(iteration) = Rewardsum;
    Rewardsum = 0;
    
    
    %additional step to be added after goal state reached
    [next, temp] = getNext(current, action, wind,temp, row, col);
    if isOverlap(next,goal) ~= 0
        rewardNew = rewardhold;
        if next.row == row && next.col >= 2 && next.col < col, % Cliff
            rewardNew = rewardneg;
            next = start;
        end
    else
        rewardNew = rewardpos;
    end
    
    
    % Episilon-greedy
    randN = 0 + (rand(1) * 1);
    if(randN > epsilon)
        [~,nextAction] = max(Q(next.row,next.col,:));
    else
        nextAction = round(1 + (rand(1) * 3)); %random integer between 1 and 4
    end
    
    nextQ = Q(next.row,next.col,nextAction);
    currentQ = Q(current.row, current.col, action);
    Q(current.row, current.col, action) = currentQ + alpha* (rewardNew + gamma*nextQ - currentQ);
    
    %converge here--------------------
    DataAnalysis = [start.row, start.col, step_save(iteration) Reward_save(iteration) iteration];
    if sum(sum(abs(newQ-Q))) < 0.0001  & sum(sum(Q>0)) & (iteration > 1000)
        temp2 = printEpisode(Q,row,col,start,goal,wind,iteration,N_decision);
        iteration
        figure('color','w');
        subplot(211); plot(1:iteration, Reward_save, 'b');
        ylabel(sprintf('Sum of Reward \nduring episode'))
        axis([0 iteration min(Reward_save)-10 max(Reward_save+10)])
        subplot(212); plot(1:iteration, step_save, 'b');
        ylabel('Steps');
        axis([0 iteration 0 max(step_save+10)])
        xlabel('Episodes')
        drawnow
        break;
    else
        newQ=Q;
        %         sprintf('Fail')
    end
    
    iteration = iteration + 1;
end

function var = isOverlap(first,second)
var = first.row - second.row;
if (var == 0)
    var = first.col - second.col;
end
end

function [pos, temp] = getNext(current, action, wind, temp, row, col)
actIndex = action;
pos = current;
if (wind(current.row, current.col) == 0)
    switch action
        case 1 %east
            pos.col= current.col + 1;
        case 2 %south
            pos.row= current.row + 1;
        case 3 %west
            pos.col= current.col - 1;
        case 4 %north
            pos.row= current.row - 1;
    end
    % else %(wind(current.row, current.col) == 1)
    %     pos.col = 1;
    %     pos.row = 4;
    
end

if pos.col <= 0,  pos.col = 1; end
if pos.col > col, pos.col = col; end
if pos.row <= 0,  pos.row = 1; end
if pos.row > row, pos.row = row; end
%----- updating temp array for printing purpose
temp(current.row, current.col, actIndex) = 1;
%-------------------------
end

function temp2 = printEpisode(Q,row,col,start,goal,wind,iteration,N_decision)
temp2 = zeros(row,col,N_decision);
current= start;
'Optimal Path :'
'Start'
current
for i = 1: 100
    [tempMax, act2] = max(Q(current.row,current.col,:));
    [next, temp2] = getNext(current, act2, wind,temp2, row, col);
    
    temp2
    act2
    next
    if (isOverlap(next,goal) == 0)
        'Reached Goal'
        break;
    end
    current = next;
end

figure('Name',sprintf('Episode: %d', iteration), 'NumberTitle','off');
ParseArrows(temp2, row, col,start,goal);
title(sprintf('Windy grid-world, Converges on episode - %d ', iteration));
end

function setPoint(x,y, matrixRow,matrixCol)
xsp = 1 / (matrixCol + 2);
ysp = 1 / (matrixRow + 2);
xcor = ((2*y + 1) / 2) * xsp;
ycor = 1 - (((2*x + 1) / 2) * ysp);
xcor = xcor - xsp/5;
plot(xcor,ycor, 'x','markersize',10,'linewidth',2);
end
