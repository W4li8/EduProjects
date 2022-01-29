function nfact=inputdata(n)
% factorial.m
%  function that computes n!

nfact=1;
for i=1:n
   nfact=i*nfact;
end