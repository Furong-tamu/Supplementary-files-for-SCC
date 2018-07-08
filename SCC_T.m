function[beta,BIC]=SCC_T(x,y,lon,lat,Lc,options)
% Description:
% Fit a spatially varying regression coefficient model using the transformed 
% SCC method. 
%       y=x_1*beta_1+x_2*beta_2+...+beta_(p+1)+epsilon
% where beta_(p+1) is generated from a spatial process 
% This routine uses the glmnet package.  


% Usage:
%     [beta,BIC] = SCC_T(x,y,options)



%INPUT ARGUMENTS
% x:       [n,p] matrix storing the p explanatory variables on n locations
% y:       [n,1] matrix storing the response variables on n locations
% lon:     [n,1] matrix storing the longitudes of n locations
% lat:     [n,1] matrix storing the latitudes of n locations
% Lc:      Cholesky matrix of covariance matrix of beta_(p+1)
% options: a structure setting the parameters used in the SCC          
%    options.lambda: a vector storing the values of tuning parametrs. 
%                 Default values are 10.^linspace(-4,3,300)
%    options_BIC: if value==1, use BIC. Otherwise, use extended BIC.
%                 Default value is 1. 


%OUTPUT ARGUMENTS
% beta:[n*p,s] matrix storing the spatially regression coefficents at s
%      different tuning parameter values. Each column beta(:,i) corresponds 
%      to the regression coeffcients at a certern tuning parameter value
%      Use command reshape(beta(:,i), [n,p]) to transfrom it into the
%      dimension same as x.
% BIC: [s,1] matrix storing the BIC or EBIC values at s different tuning
%      parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%DATE: 15 May 2018

        

if isfield(options,'lambda')==1
    if isempty(options.lambda)==0
        
    else
       options.lambda=10.^linspace(-4,3,300); % Use default value  
        
    end
else
    options.lambda=10.^linspace(-4,3,300); % Use default value  
end

if isfield(options,'BIC')==1
    if isempty(options.BIC)==0
        
    else
       options.BIC=1; % Use default value  
        
    end
else
    options.BIC=1; % Use default value  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




[n,p]=size(x);
Xg=zeros(n,n*p);


for j=1:p
    Xg(:,(j-1)*n+1:j*n)=diag(x(:,j));
end

% Compute n*(n-1) matrix constructed from edge set of Minimum spanning tree  
[H]=SCC_spanning_tree(lon,lat,p,0.1);

G=Xg/H;

options.standardize = false;
options.penalty_factor=ones(n*p,1);
options.penalty_factor(end-p+1:end)=0;
options.intr=false; 
FitInfo = glmnet(Lc\G,Lc\y,[],options);
B=FitInfo.beta;
beta=H\B;
[MSE]=SCC_fit_MSE(B,Lc\G,Lc\y,FitInfo.a0);
k=FitInfo.df;
if options.BIC==1
    % usuing BIC
    BIC=n*log(MSE)+k*log(n);
else
    % using EBIC
    BIC_add=nan(length(k),1);
    for qqq=1:length(k);
        ccc1=n*p:-1:(n*p-k(qqq)+1);
        ccc2=1:k(qqq);
        BIC_add(qqq)=2*(sum(log(ccc1))-sum(log(ccc2)));
    end
    BIC=n*log(MSE)+k*log(n)+BIC_add;
end

end


% Subroutine SCC_fit_MSE
function[MSE]=SCC_fit_MSE(B,G,y,a)
[~,s]=size(B);
n=length(y);
a=ones(n,1)*a';
y=y*ones(1,s);
MSE=sum((y-G*B-a).*conj(y-G*B-a))';
end
%--------------------------------------------------------------------------


