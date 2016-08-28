function [bestTau,bestSRV,bestMu] = optimizeParameters(tauRange,srvRange,mobRange,N_max,N_store)
global Rlightfilter muTauVsRMSPlot muTauVsRlightPlot
for honing = 1:4;
    % decreasing the window where things are being searched
    for i=1:N_max
           % Guess some random parameters out of the initial range
           tau_guess = tauRange(1) + (tauRange(2)-tauRange(1)).*rand(1);
           srv_guess = srvRange(1) + (srvRange(2)-srvRange(1)).*rand(1);
           mu_guess = mobRange(1) + (mobRange(2)-mobRange(1))*rand(1);

           % With those properties, calculate the resulting function:
           deltaN= solver1(tau_guess);

           % Now compare what you just calculated to the "true" value that you 
           % measured, to get an RMS error value. Here I'm calculating the 
           % RMS error in EQE for each proposed fit
           RlightCalculate = calculateRlight(deltaN,mu_guess);
           RMS = abs(Rlightfilter - RlightCalculate);

           % If this is one of the first few simulations, just save the result
            if i<=N_store;
                % Store these "guesses" in a row of the matrix, and also store the
                % RMS associated with it
                L_store(i,:) = [tau_guess,srv_guess,mu_guess];
                RMS_store(i) = RMS;

           else
                % If you're beyond the first few guesses, now you have to decide
                % whether to save it. Look for the worst fit (max RMS) and replace 
                % this set of parameters if a better fit is found
                [y,j] = max(RMS_store);
                if RMS < y;
                    L_store(j,:) = [tau_guess,srv_guess,mu_guess];
                    RMS_store(j) = RMS;

                end
           end
        end

            % Now that you've tried 3000 fits and saved the best 50, use those 50 
            % best fits to redefine the range. Then go ahead and repeat the process
            % with your new range.
            tauRange = [min(L_store(:,1)),max(L_store(:,1))];
            srvRange = [min(L_store(:,2)),max(L_store(:,2))];
            mobRange = [min(L_store(:,3)),max(L_store(:,3))];
            % N_max = 100000;
        muTauVsRMSPlot = figure(1);
        hold on;
        plot(L_store(:,3).*L_store(:,1)*10^4,RMS_store,'o');
        xlabel('Mu-tau value (in cm^2/V');ylabel('RMS')
        title('RMS')
        
        muTauVsRlightPlot = figure(2);
        hold on;
        plot(L_store(:,1).*L_store(:,3)*10^4,RlightCalculate,'o');
        title('Rlight Calculated')
        xlabel('Mu-Tau value (in cm^2/V)');ylabel('Rlight')
        
        % At the end, you have 50 "best fits". You can plot them all, or just save
        % the best one. 
        [heart,ih] = min(RMS_store);
        % Print out the best set of parameters and the corresponding error:
            bestTau = L_store(ih,1);
            bestSRV = L_store(ih,2);
            bestMu = L_store(ih,3);
            heart;
end
