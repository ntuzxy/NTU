function[v1,v2]=RandDistr(input,l_v1)
% randomly distribute value saved in input into v1 and v2 in sizes of l_v1
% and length(input)-l_v2 respectively

l_v=length(input);
ind1=zeros(1,l_v);
ind2=ones(1,l_v);
for i=1:1:l_v1
    tmp=randi([1 l_v],1);
    while ind1(tmp)
        tmp=randi([1 l_v],1);
    end
    ind1(tmp)=1;
    ind2(tmp)=0;
end
v1=input(find(ind1));
v2=input(find(ind2));

