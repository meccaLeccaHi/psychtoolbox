function SimpleMoviePrez
% SimpleMoviePrez.m
% Randomizes and presents movies.
%
% last modified
% apj 9/16/16

% Check if Psychtoolbox is properly installed:
AssertOpenGL;

REPS                                = 1; % Repetitions of stimuli
ISI                                 = .5; % Interstimulus interval (seconds)
JITTER                              = .1; % +/- ISI
SCALE                               = .5;

screensize                          = get(0, 'Screensize' );
windowrect                          = [0 0 screensize(3:4)];

ptd_size                            = 75;
photodiode_rect                     = [windowrect(3:4)-ptd_size windowrect(3:4)];
photodiode_color                    = [255 255 255];
photodiode_off_color                = [0 0 0];

%% declare paths and filenames
[~,hostname]                        = system('hostname');
if isunix
    if regexp(hostname(1:3),'pre')
        stim_dir        = '/home/presentation1/Desktop/Experiment_Files/Jones/Jones_StimSet';
    else
        stim_dir        = '/media/sf_nextCloud/Cloud2/movies/presentation/Jones_StimSet'; % Stimulus path
    end
else
    stim_dir            = 'C:\Users\adam\ownCloud\Cloud2\movies\presentation\Jones_StimSet'; % Stimulus path
end
header_dir                          = fullfile(stim_dir,'headers');

foo                                 = dir(fullfile(stim_dir,'*.avi')); % movie stimuli
movies_orig                         = {foo(:).name}';  % file list

new_order                           = randperm(length(foo));
movies                              = movies_orig(new_order,:);
exp_header                          = cell(length(movies)*REPS,8);
MOVIE_NUM                           = 1;
STIM_NUM                            = 2;
MOVIE_NAME                          = 3;
SCALE_FACTOR                        = 5;
OPEN_SCREEN                         = 5;
CLOSE_SCREEN                        = 6;
END_ISI                             = 7;
JIT_ISI                             = 8;

jit_times                           = randi([ISI-JITTER,ISI+JITTER]*100,...
                                        length(movies)*REPS,1)./100;
                                    
% Wait until user releases keys on keyboard:
KbReleaseWait;

% Select screen for display of movie:
screenid                            = max(Screen('Screens'));

try
    % Open 'windowrect' sized window on screen, with black [0] background color:
    win                             = Screen('OpenWindow',screenid,0,windowrect);
    black                           = BlackIndex(win);
    
    % Create photodiode signal textures
    imgmx                           = permute(photodiode_color(:),[2 3 1]);
    imgmx0                          = permute(photodiode_off_color(:),[2 3 1]);
    photodiode_tex(1)               = Screen('MakeTexture',win,imgmx);
    photodiode_tex(2)               = Screen('MakeTexture',win,round(imgmx*2/3));
    photodiode_tex(3)               = Screen('MakeTexture',win,imgmx0);
    
    % Repetition loop
    for rep = 1:REPS
        
        % Stimulus loop
        for mov = 1:3%length(movies)
            
            % Add info to exp. header file
            moviename                       = fullfile(stim_dir,movies{mov});
            spot                            = mov+((rep-1)*length(movies));
            exp_header{spot,MOVIE_NUM}      = num2str(mov);
            exp_header{spot,STIM_NUM}       = num2str(spot);
            exp_header{spot,MOVIE_NAME}     = moviename;
            exp_header{spot,SCALE_FACTOR}   = num2str(SCALE);
            exp_header{spot,OPEN_SCREEN}    = GetSecs;
            
            % Open movie file:
%             [movie,movie_dur,fps,mov_wdth,mov_hgt,count,aspectRatio] ...
            [movie,~,~,~,~,~,~]             = Screen('OpenMovie',win,moviename);

            % Start playback engine:
            Screen('PlayMovie',movie,1);
            
            % Playback loop: Runs until end of movie or keypress:
            while ~KbCheck
                
                % Wait for next movie frame, retrieve texture handle to it
                tex                         = Screen('GetMovieImage',win,movie);
                
                % Valid texture returned? A negative value means end of movie reached:
                if tex<=0
                    % We're done, break out of loop:
                    break;
                end
                
                % Draw the new texture immediately to screen:
                Screen('DrawTexture',win,tex); % movie texture ,[],foo,0
                Screen('DrawTexture',win,photodiode_tex(1),[],photodiode_rect); % photodiode texture
                
                % Update display:
                Screen('Flip',win);
                
                % Release texture:
                Screen('Close',tex);
            end
            
            % Stop playback:
            Screen('PlayMovie',movie,0);
            
            % Close movie:
            Screen('CloseMovie',movie);
            exp_header{spot,CLOSE_SCREEN}       = GetSecs;
            
            % Show black screen for ISI
            Screen('DrawTexture',win,photodiode_tex(3),[],photodiode_rect);
            Screen('FillRect',win,black); % fill the screen with black
            Screen('Flip',win); % present to the screen
            WaitSecs(jit_times(mov + ((rep-1)*length(movies)))); % Wait until the value of ISI
            exp_header{spot,END_ISI}            = GetSecs;
            exp_header{spot,JIT_ISI}            = jit_times(mov + ((rep-1)*length(movies)));
            
        end
        
    end
    
    % Close Screen, we're done:
    Screen('CloseAll');
    
catch %#ok<CTCH>
    sca;
    psychrethrow(psychlasterror);
end

% add header labels to header matrix
save_header                 = [{'MOVIE_NUM';'STIM_NUM';'MOVIE_NAME';'SCALE_FACTOR';'OPEN_SCREEN';'CLOSE_SCREEN';'END_ISI';'JIT_ISI'}';exp_header];

% save header to csv file
if ~exist(header_dir,'dir')
    mkdir(header_dir)
end
savename                    = fullfile(header_dir,['header_' datestr(now,'mmDDYY_hhMM') '.csv']);
cell2csv(savename,save_header)
disp(['saved header file:' savename])

return
