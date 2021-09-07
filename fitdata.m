close all
clear

% load
filename = './data.xlsx';
data = readmatrix(filename,'FileType','spreadsheet');

X = data(:,1); % thickness
Y1 = data(:,2); %  resistivity_as-dep (\muOhm-cm)
Y1_sd = data(:,3);
Y2 = data(:,4); %  resistivity_as-dep (\muOhm-cm)
Y2_sd = data(:,5);

% select dataset to fit
if 0
    Y = Y1;
    Y_sd = Y1_sd;
else
    Y = Y2;
    Y_sd = Y2_sd;
end

%% sample
% Artificially generate n_sample samples for Monte Carlo estimator 
% on each datapoints.
n_sample = 1000; 

% Y1
X_sample = [];
Y_sample = [];
for i = 1:length(Y)
    X_sample_i = [];
    Y_sample_i = [];    
    for j = 1:n_sample
        Y_sample_j = Y(i) + normrnd(0,1)*Y_sd(i);
        Y_sample_i = [Y_sample_i;Y_sample_j];
        X_sample_i = [X_sample_i;X(i)];
    end
    X_sample = [X_sample;X_sample_i];
    Y_sample = [Y_sample;Y_sample_i];
end

%% Fit
% some constants
rho_0 = 7.3;
r = 0.65;
lambda = 6.59;

if 1 % use erf
    model = '(1+3*6.59*(1-a)/(4*x)+3*6.59*0.65/(2*(x^((d-e)/2*(1-erf((x-b)/c))+e))*(1-0.65)))*7.3';
    fo = fitoptions('Method','NonlinearLeastSquares',...
    'Lower',     [0,  0.0,  0.0, 0.50, 0.30],...
    'Upper',     [1,  100,  100, 1.00, 0.80],...
    'StartPoint',[0.4, 40, 20.0, 0.75, 0.62]);
    ft = fittype(model,'options',fo);
    [curve,gof] = fit(X_sample,Y_sample,ft);
    Cf = coeffvalues(curve);
    Ci = confint(curve,0.95);
    Cf_err = (Ci(2,:)-Ci(1,:))/2;

    X_fitted = 1:300;
    Y_fitted = (1+3*6.59*(1-Cf(1))./(4*X_fitted)+3*6.59*0.65./(2*(X_fitted.^((Cf(4)-Cf(5))/2*(1-erf((X_fitted-Cf(2))/Cf(3)))+Cf(5)))*(1-0.65)))*7.3;
    
else
    model = '(1+3*6.59*(1-a)/(4*x)+3*6.59*0.65/(2*(x^0.41)*(1-0.65)))*7.3';
    fo = fitoptions('Method','NonlinearLeastSquares',...
    'Lower',     [0],...
    'Upper',     [1],...
    'StartPoint',[0.4]);
    ft = fittype(model,'options',fo);
    [curve,gof] = fit(X_sample,Y_sample,ft);
    Cf = coeffvalues(curve);

    ci = confint(curve,0.68);

    X_fitted = 1:300;
    Y_fitted = (1+3*6.59*(1-Cf(1))./(4*X_fitted)+3*6.59*0.65./(2*(X_fitted.^0.41)*(1-0.65)))*7.3;
    Y_fitted2 = (1+3*6.59*(1-1)./(4*X_fitted)+3*6.59*0.65./(2*(X_fitted.^0.41)*(1-0.65)))*7.3;
end

disp(['p     = ',num2str(Cf(1),'%0.2f'),' +- ',num2str(Cf_err(1),'%0.2f')])
disp(['d_0   = ',num2str(Cf(2),'%0.2f'),' +- ',num2str(Cf_err(2),'%0.2f')])
disp(['c     = ',num2str(Cf(3),'%0.2f'),' +- ',num2str(Cf_err(3),'%0.2f')])
disp(['n_0   = ',num2str(Cf(4),'%0.2f'),' +- ',num2str(Cf_err(4),'%0.2f')])
disp(['n_inf = ',num2str(Cf(5),'%0.2f'),' +- ',num2str(Cf_err(5),'%0.2f')])

figure()
hold on
plot(X_fitted,Y_fitted)
ylim([0,50])
errorbar(X,Y,Y_sd,'sk')