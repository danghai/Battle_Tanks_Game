% Yuta Kuboyama

% Converts a segment of a wavefile into coe format.

% filename : name of wavefile, eg 'violin.wav'
% start : starting index of segment
% finish : final index of segment
% channel : 1 for left channel, 2 for right channel.
% output_name : name of output coe file, eg "violin.coe"
% scaling_factor : scale factor for amplitude.
% bit_width : number of bits per sample.
%[y,fs] = audioread('balu.mp3');
% x = resample(y,8000,fs);
% z = audioinfo(x);

% Example:
% makecoe('violin.wav', 1, 15000, 1, 'violin.coe', 10000, 16);
% makecoe('lion.wav', 1, 10857, 1, 'lion.coe', 15, 4)
% makecoe('ktc.mp3', 1, 189033, 1, 'ktc.coe', 128, 8)
% makecoe('balu.mp3', 1, 1283324, 1, 'balu.coe', 128, 8)
% makecoe('balu_converted.mp3', 1, 234432, 1, 'balu1.coe', 127, 8)
% makecoe('naveen_ringtone_converted.mp3', 1, 105408, 1, 'naveen1.coe', 127, 8)
% makecoe('kabali_telugu.mp3', 8000,1,205217, 1, 'kabali_telugu1.coe', 127, 8)

% This takes samples 1-15000 from the left channel of violin.wav, and
% multiplies each sample by scale factor 10000. Then, it outputs the coe
% file violin.coe, with 16-bit wide data per memory address.
%function output = makecoe(filename,sample_freq,start,finish,channel,output_name,scaling_factor,bit_width)

function output = makecoe(filename,start,finish,channel,output_name,scaling_factor,bit_width)

disp('Converting data into binary...')


input =  audioread(filename);

%resampled = downsample(input,5);

data = input(start:finish,channel);

scaled_data = data*scaling_factor;
rounded_data = round(scaled_data);

bits_table = dec2bit(rounded_data,bit_width);

disp('done.')
disp(' ')
disp('Formatting output...')

output = addcomma(bits_table);

file = fopen(output_name,'w');
fprintf(file,'memory_initialization_radix=2;\n');
fprintf(file,'memory_initialization_vector=\n');
dlmwrite(output_name,output,'-append','delimiter','', 'newline', 'pc');
disp('done.')

end

% Given a list of integers (input_data), returns them in 
% binary with number of bits specified by (bits).

function output = dec2bit(input_data, bits)

for i = 1:length(input_data)
    
        data(i) = input_data(i)+ 128;
    
end

output = dec2bin(data,bits); %get binary representations

end

% Adds comma to each entry of the data.

function output = addcomma(data)

rowxcolumn = size(data);
rows = rowxcolumn(1);
columns = rowxcolumn(2);

output = data;

for i = 1:(rows-1)
    output(i,(columns+1)) = ',';
end

output(rows,(columns+1)) = ';';

end