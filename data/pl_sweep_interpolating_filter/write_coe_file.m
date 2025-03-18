function write_coe_file(fname,filt_coefs)
%write_coe_file Summary of this function goes here
%   Detailed explanation goes here

filename=fname;
fid = fopen(filename, 'w');
fprintf(fid, 'radix = 10;\n');
fprintf(fid, 'coefdata = \n', filt_coefs(1));
for i = 1:length(filt_coefs)-1
    fprintf(fid, '%.15f,\n', filt_coefs(i));
end
fprintf(fid, '%.15f\n', filt_coefs(end));
fclose(fid);
end

