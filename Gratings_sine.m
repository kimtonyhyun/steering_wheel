function [visual_cursor] = Gratings_sine ; 
% 220419 the BG should not be bright, should be the darkest. Stripes should be brighter than BG

%close all
cycles = 7; 3.5;
angle =   -45;    -30;     -10;    0;     45;    20;  %degree
constant = (angle/180*pi)/(pi/4); angle/45;
increment = 0.1;
sigma_index = 10; 6;

t = [0:increment:2*cycles*pi];
t_dash = [0 : increment*(1+abs(angle)/180*pi) : 2*cycles*pi];
t_dash(length(t)+1:end) = [];
frameNum = length(t_dash);
a = sin(t_dash);
for i = 1:frameNum
    a(i,:) = sin(t_dash-increment*i*constant);
    
    % adjusting the brightness
    a(i,:) = a(i,:) / 2.5 + 0.6;
end
% a = (a - min(min(a)));
% a = a./max(max(a));

Gaussian_Linear = zeros(size(a,1)*2,1);
Gaussian_Linear(round(size(Gaussian_Linear,1)/2),1) = 1;
sigma = frameNum / sigma_index; 
degree = 360*cycles/frameNum;
sigma_angle = sigma*degree;
[Gaussian_Linear]=gaussian_local(Gaussian_Linear.',sigma);
Gaussian_Linear = Gaussian_Linear/max(Gaussian_Linear);


Gaussian_distance = a * 0;
Gaussian_prob = a * 0;
a_gaussian = a;
for i = 1:size(Gaussian_distance,1)
    for j = 1:size(Gaussian_distance,2)
        Distance = sqrt( (round(size(Gaussian_distance,1)/2)-i)^2  + (round(size(Gaussian_distance,2)/2)-j)^2  );
        Gaussian_distance(i,j) = Distance;
        Gaussian_prob(i,j) = Gaussian_Linear( round( round(size(Gaussian_Linear,1)/2) + Distance));
        Gaussian_prob(i,j) = Gaussian_prob(i,j);
        a_gaussian(i,j) = a(i,j)*Gaussian_prob(i,j);
    end
end

% imagesc(Gaussian_prob);colorbar;

% figure
% I = imagesc(a_gaussian);daspect([1 1 1])
% colormap(gray);colorbar;

visual_cursor = a_gaussian;
end


function [Datafilt]=gaussian_local(Data,sigma);
if sigma>0
    Range=400;%ƒJ?[ƒlƒ‹ƒeƒ“ƒvƒŒ?[ƒg‚Ì•Ð‘¤ƒsƒNƒZƒ‹?”?B?ÅŒã‚Ì•û‚Í‚Ù‚Æ‚ñ‚Çƒ[ƒ?‚Å‚ ‚é‚±‚Æ‚ª–]‚Ü‚µ‚¢?B‚ ‚Ü‚èRange‚ª‘å‚«‚¢‚Æ‰ð?Í‚ÌŽžŠÔ‚Î‚Á‚©‚è?H‚¤‚Ì‚Å‚Í‚È‚¢‚©?B

    %1ŽŸŒ³ƒf?[ƒ^‚©2ŽŸŒ³ƒf?[ƒ^‰»‚ðŒˆ‚ß‚é
    dimen = 1;
    if (size(Data,1)>1)&&(size(Data,2)>1);
        dimen=2;
    end

    %Žw’è‚µ‚½ƒpƒ‰ƒ??[ƒ^‚É‚¨‚¯‚éƒJ?[ƒlƒ‹‚Ìƒeƒ“ƒvƒŒ?[ƒg‚ð?ì?¬
    if dimen==1;
        for x=0:Range
            Prima  = (1/sqrt(2*pi*sigma^2))^dimen ;
            HeHowa = x^2;
            Secon  = exp(-HeHowa/(2*sigma^2)) ;
            Tiert  = Prima * Secon ;
            Kernel_gain(x+1)=Tiert;
        end
    else
        for x=0:Range
            for y=0:Range
                Prima  = (1/sqrt(2*pi*sigma^2))^dimen ;
                HeHowa = x^2+y^2 ;
                Secon  = exp(-HeHowa/(2*sigma^2)) ;
                Tiert  = Prima * Secon ;
                Kernel_gain(x+1,y+1)=Tiert;
            end
        end
    end
    Kernel_gain;
    %ƒf?[ƒ^‚Ì’l‚ÉŽÀ?Û‚ÌƒQƒCƒ“‚ð‚©‚¯‚é?BŒÂ?X‚Ìƒf?[ƒ^“_‚É‚Â‚¢‚Äƒ‹?[ƒv‚Å‚Ç‚ñ‚Ç‚ñŒvŽZ‚µ‚Ä‚¢‚­
    if dimen==1
        Datafilt=zeros(length(Data) , 1);
        Gain_added=zeros(length(Data) , 1);

        for i=1:length(Data)
            for i2=1:length(Data)
                if abs(i-i2)<=Range
                    Datafilt(i,1)=Datafilt(i,1) + Kernel_gain(abs(i-i2)+1) * Data(i2);
                    Gain_added(i,1)=Gain_added(i,1)+Kernel_gain(abs(i-i2)+1);
                end
            end
        end
    else
        Datafilt=zeros(size(Data,1) , size(Data,2));
        Gain_added=zeros(size(Data,1) , size(Data,2));
        for i=1:size(Data,1)
            for j=1:size(Data,2)

                for i2=1:size(Data,1)
                    for j2=1:size(Data,2)

                        if (abs(i-i2)<=Range)&&((abs(j-j2)<=Range))
                            Datafilt(i,j)=Datafilt(i,j) + Kernel_gain(abs(i-i2)+1,abs(j-j2)+1) * Data(i2,j2);
                            Gain_added(i,j)=Gain_added(i,j)+Kernel_gain(abs(i-i2)+1,abs(j-j2)+1);
                        end

                    end
                end
            end
        end
    end

    %’[‚Ì’l‚ð•â?³
    MAX=max(max(Gain_added));
    for i=1:size(Datafilt,1)
        for j=1:size(Datafilt,2)
            Datafilt(i,j)=Datafilt(i,j)*MAX/Gain_added(i,j);
            Gain_added2(i,j)=Gain_added(i,j)*MAX/Gain_added(i,j);
        end
    end
    Datafilt=Datafilt/MAX;
else
    Datafilt=Data;
end
end