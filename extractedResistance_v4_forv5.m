%% This file takes a 'name_extracted.mat' file and finds resistance by averaging 
% the horizontal and vertical resistances in the cell. This file also finds the 
% associated properties of measurement (T, illumination, V, I).
% It then saves these in a summary file called 'name_summary.mat'

% =========================================================================
%  Works with: GaAs sample 1, SnSo filters, dark and normal
%  (When there is an additional _ in the name)
% =========================================================================
%% 
% MUST CHANGE DIMENSIONS for different samples
% If calling from main.m have this a function; if using separetely comment
% that out and request the name.
function [] = extractedResistance_v4_forv5(name)

% request sample name from user
%name = input('What is the sample name? ', 's');
length_name = length(name);

% if not in the same folder give path or folder name
path = 'DataAnalysis/';
% load sample as a 
sample = load([path name '_extracted.mat']);

% get the size of the data
Tn = length(sample.T);
T = sample.T; 
illn = length(sample.ill1);
ill = sample.ill1;

% full list of optical density percentages from Si calibration
G_ODpercent = [0,1.25,0.365,0.107,0.0200,0.0032,0.000647,1.12,0.329,0.0967,0.0181,0.00289,0.00059,0.834,0.245,0.0716,0.0134,0.00214,0.000446,0.617,0.184,0.0548,0.0103,0.00165,0.000351,0.506,0.153,0.0457,0.00857,0.00138,0.0003,0.296,0.0887,0.0268,0.00499,0.000819,0.000195]; 

thickness = 10^-6; %[µm = 10^-6 m]     % Device thickness

% Device properties -> SnS
area = thickness*7.22*10^-3; %[m^2]    % Device area. Thickness * Width of bar
deviceLength = 750*10^-6; %[µm = 10^-6 m]    % Device Length

% Device properties -> GaAs
% area = thickness*10.4*10^-3;
% deviceLength = 13*10^-3;

% start
for Ti = 1:Tn
    rSheeti = 0;
    for illi = 1:illn % over every illumination value for every temperature
     
     rSheeti = rSheeti+1;
          
     % list for calculating muTau at end of code
      G_ODinput = G_ODpercent(ill(illi));
      G_OD(rSheeti) = G_ODinput;    
     
% sample.mat should have within it -> name, T, Ill, {VI} 

     Voltage = sample.VI{Ti,ill(illi),1}; 
     Current = sample.VI{Ti,ill(illi),2};
    
     mb = polyfit(Voltage,Current,1);
     Resistance = 1/mb(1); % Resistance = slope of IV curve
    RList(Ti,rSheeti) = Resistance;
     
% =========================================================================
% End of main loop
% =========================================================================
        
        
    end % illumination loop
        
end % temp loop

% =========================================================================
% Calculating Simplified muTau product
% =========================================================================

resistivity = RList.*(area/deviceLength); %[Ohm*m]

% acquiring mu*Tau product in simplest case
sigma = 1./resistivity; % [1/Ohm*m] Area is infinite

% sigma needs to subtract background dark current

% G in [m^-3*s^-1] assuming no depth dependence and full absorption
% SnS
% G = 2.8454*10^21/thickness;
% GaAs
G = 2.0781*10^21/thickness; %[m^-3*s^-1]
% G will change proportionally with each new optical density
q = 1.602*10^-19; % [A*s] charge of an electron

sigmaDark = sigma(:,1);

for indx = 1:length(sigmaDark)
    
deltaSigma(indx,:) = sigma(indx,:)-sigmaDark(indx);

end

for illi = 1:illn
    
    muTaui(:,illi) = deltaSigma(:,illi)/((G*G_OD(illi)*q))*10^4; % [cm^2/V]
    format shortE
end


PlotStyle1 = {'h','p','<','^','s','+','x','o','*','.','d','v','>','-',':','-.','--','b','g','r','k','m'};
PlotStyle2 = {'h','p','<','^','s','+','x','o','*','.','d','v','>','-',':','-.','--','b','g','r','k','m'};

%==========================================================================
% Plot Conductivity as a function of Illumination
%==========================================================================
figure(1)

for Tindex = 4:(Tn) 
    TLegend{Tindex-3}=num2str(T(Tindex)*100);
    for num = [2,3,4,6,7,9,10] 
        
        sigmaPlot1(num)=log10(deltaSigma(Tindex,num));
        G_ODPlot1(num)=G_OD(num)*100;
        
    end
    hold on
    plot(log10(G_ODPlot1),sigmaPlot1,PlotStyle1{Tindex})
    legend(TLegend)
    xlabel('Log10(Illumination) [%]')
    ylabel('Log10(??) [1/?*m]')
end

% %==========================================================================
% % Plot Conductivity as a function of Temperature
% %==========================================================================
% figure(2)
% 
% for num = [2,3,4,6,7,9,10] % 1:(illn) 
%     %IllLegend{num}=num2str(G_OD(num)*100);
%     for Tindex = 4:(Tn)
%         
%         sigmaPlot2(Tindex-3)=log10(deltaSigma(Tindex,num));
%         Tplot2(Tindex-3)=T(Tindex)*100;
%         
%     end
%     hold on
%     plot(Tplot2,sigmaPlot2,PlotStyle2{num})
%     IllLegend = {num2str(G_OD(2)*100),num2str(G_OD(3)*100),num2str(G_OD(4)*100),num2str(G_OD(6)*100),num2str(G_OD(7)*100),num2str(G_OD(9)*100),num2str(G_OD(10)*100)};
%     legend(IllLegend)
%     xlabel('Temperature [K]')
%     ylabel('Log10(??) [1/?*m]')
%     
% end
% 
% %==========================================================================
% % Plot muTau as a function of T
% %==========================================================================
% figure(3)
% 
% for num = [2,3,4,6,7,9,10]% 1:(illn) % consider log scale 
%     %IllLegend{num}=num2str(G_OD(num)*100);
%     for Tindex = 4:(Tn)
%         
%         muTauiPlot3(Tindex-3)=log10(muTaui(Tindex,num));
%     
%     end
%     hold on
%     plot(Tplot2,muTauiPlot3,PlotStyle2{num})
%     IllLegend = {num2str(G_OD(2)*100),num2str(G_OD(3)*100),num2str(G_OD(4)*100),num2str(G_OD(6)*100),num2str(G_OD(7)*100),num2str(G_OD(9)*100),num2str(G_OD(10)*100)};
%     legend(IllLegend)
%     xlabel('Temperature [K]')
%     ylabel('Log10(µ?) [cm^2/V]')
%     
% end
% 
% %==========================================================================
% % Plot muTau as a function of illumination
% %==========================================================================
% figure(4)
% 
% for Tindex = 4:(Tn) % consider log scale
%     TLegend{Tindex-3}=num2str(T(Tindex)*100);
%     for num = [2,3,4,6,7,9,10] %1:(illn) 
%         
%         muTauiPlot4(num)=log10(muTaui(Tindex,num));
%         G_ODPlot4(num)=G_OD(num)*100;
%         
%     end
%     hold on
%     plot(log10(G_ODPlot4),muTauiPlot4,PlotStyle1{Tindex})
%     legend(TLegend)
%     xlabel('Log10(Illumination) [%]')
%     ylabel('Log10(µ?) [cm^2/V]')
% end

% =========================================================================
% Derivation of simplified muTau
% =========================================================================

% dn = G[#electrons/m^3/s]*tau
% sigma = dn*mu*q
% sigma = G*tau*mu*q = -d/A*slope

% how many photons hit the sample for 1 sun? (black body solar spectrum)
% #photons/wavelength or power/wavelength
% what is alpha - how many photons are absorbed/unit distance

% Sns band gap = 1.1eV -> 1127 nm
% all photons>1.1eV are absorbed - total photon flux of 2.8454E21 [m^-2*s^-1]
% assuming uniform generation across entire sample: photon flux/thickness =
% G = 2.8454E27 [m^-3*s^-1]
% abs coefficient = 10^4 [cm^-1]
% q = 1.602*10^-19

% =========================================================================
% Save everything
% =========================================================================

mkdir('DataAnalysis') % makes a folder to put extracted.mat files into if 
% it doesn't already exist
save(['DataAnalysis/' name '_summary.mat'], 'name', 'T', 'ill', 'RList') 
% clear all
% you can open this as a structure by sample_name1 = load(name.mat), then
% everthing will be available as sample_name1.T, sample_name1.avgRho, etc
% That way you could load more than one sample at the same time

end
% =========================================================================
% Purpose of Code
% =========================================================================

% make intensity vector corresponding to illumination values to get
% appropriate value of G, generation rate
% illumination values need to have 2 subtracted from them to go back to
% original values (check within files for true values, not title)
% Barrera will need [Sheet Resistance, Illumination]
