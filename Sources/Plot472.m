%%% do plot(x,y) for og graph lmao
x = zeros(1,1024);
count = 0;
for i= 1:1024
    x(i) = count;
    count= count+1;
end


y1 = dlmread('output1.txt','r');
for i= 1:1024
    y(i) = y1(i);
end
figure

%plot(x,abs(fft2(double(y)))) %fft
%plot(x,y)% og 
x1 = coord(159);
Ysnap1 = snap(y1,159);
%plot(x1,Ysnap1)% 2 cycles
%%%%%%%%%%%%%
y2 = dlmread("output2.txt",'r');
for i= 1:1024
    y(i) = y2(i);
end
figure
%plot(x,abs(fft2(double(y))))
%plot(x,y)
x2 = coord(187);
Ysnap2 = snap(y2,187);
%plot(x2,Ysnap2)

%%%%%%%%%
y3 = dlmread("output3.txt",'r');
for i= 1:1024
    y(i) = y3(i);
end
figure
%plot(x,abs(fft2(double(y))))
%plot(x,y)
x3 = coord(164);
Ysnap3 = snap(y3,164);
%plot(x3,Ysnap3)

%%%%%%%%%%%55
y4 = dlmread("output4.txt",'r');
for i= 1:1024
    y(i) = y4(i);
end
figure
plot(x,abs(fft2(double(y))))
%plot(x,y)
x4 = coord(200);
Ysnap4 = snap(y4,200);
%plot(x4,Ysnap4)


function x = coord(size)
x = zeros(1,size);
count = 0;
for i= 1:size
    x(i) = count;
    count= count+1;
end
end

function ret = snap(y,size)
for i = 1:1024
  ret(i) = y(i);
  if(size ==i)
  break 
  end
end
end
