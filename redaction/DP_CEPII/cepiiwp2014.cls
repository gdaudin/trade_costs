%% This is file `cepiiwp2014.cls' based on 'article.cls'
%% créé par Benjamin Carton - 27/11/2007
%% Il permet la mise en page automatique des documents de travail du CEPII.
\NeedsTeXFormat{LaTeX2e}[1995/12/01]
\ProvidesClass{cepiiwp2014}[2013/10/11 v1.1 Standard LaTeX class]
\DeclareOption{twocolumn}{\OptionNotUsed} % pas de documents à 2 colonnes
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
% pour une version "draft"
\newif\ifDraftcepii
\DeclareOption{draftcepii}{\Draftcepiitrue}
\newif\ifFrenchcepii
\DeclareOption{frenchcepii}{\Frenchcepiitrue}
\ProcessOptions\relax
\LoadClass[onecolumn,12pt,a4paper,twoside]{article}

\RequirePackage{fancyhdr} % entêtes et pieds de page
\RequirePackage{cmbright}
\RequirePackage[T1]{fontenc}
\RequirePackage{caption}
\RequirePackage{titlesec} % format des titres
\RequirePackage[marginal]{footmisc}
\RequirePackage[colorlinks=true,urlcolor=blue,linkcolor=black,citecolor=black]{hyperref}
\ifFrenchcepii
\RequirePackage[english,french]{babel}
\fi

%%%%%%%%%%%%%%%%%%
% POLICES ENVISAGEES :
%\RequirePackage{mathptmx} % police
%\RequirePackage[math]{iwona}
%\RequirePackage[condensed,math]{iwona}
%\RequirePackage[light,math]{iwona}
%\RequirePackage[light,condensed,math]{iwona}
%\RequirePackage[condensed,math]{kurier}
%\RequirePackage[math]{kurier}
%\RequirePackage[sfmath]{kpfonts}
% pour kpfonts
% \renewcommand{\familydefault}{\sfdefault}


% utile pour les graphiques
% \definecolor{greencepii}{RGB}{0,130,112} % {rgb}{0,0.51,0.44}
% \definecolor{greycepii}{RGB}{137,142,140} % {rgb}{0.54,0.56,0.55}



\newcounter{footnotememory}
%\def\entitle#1{\gdef\@entitle{#1}}

% ------------------------
% éléments de mise en page
% ------------------------
%vertical (page)
% tout en haut : 1 inch = 25.4mm + 7mm ajoutés par latex (pourquoi ?)
\setlength{\voffset}{-2.5mm} %positionnement haut de page
\setlength{\headheight}{6mm} % hauteur de l'entête
\setlength{\headsep}{5mm} % hauteur entre entête et haut de texte
\setlength{\textheight}{218mm} % hauteur du texte
\setlength{\footskip}{13mm} % bas de texte / bas de numéro de page
% horizontal (page)
% tout à gauche : 1 inch = 25.4mm
\setlength{\oddsidemargin}{-5mm} % marge de gauche des pages impaires
\setlength{\evensidemargin}{-5mm} % marge de gauche des pages pairs
\setlength{\textwidth}{170mm} %largeur du texte
% paragraphes
\setlength{\parindent}{0cm} %pas d'alinéa
\setlength{\parskip}{1.8ex plus 0.2ex minus 0.2ex} % espace entre les paragraphes
% notes de bas de page
\setlength{\footnotemargin}{8pt}
% titre de figures te tableaux
\captionsetup{margin=10pt,font={small,bf},labelfont={small,bf},labelsep=endash}
\setlength{\abovecaptionskip}{5pt}
\setlength{\belowcaptionskip}{0pt}
% entête
\pagestyle{fancy}
\fancyhead{}
\ifDraftcepii
\renewcommand{\headrulewidth}{0pt}
\else
\ifFrenchcepii
\fancyhead[L]{\raisebox{4pt}{\footnotesize{\emph{Document de travail du CEPII}}}}
\else
\fancyhead[L]{\raisebox{4pt}{\footnotesize{\emph{CEPII Working Paper}}}}
\fi
\fancyhead[R]{\raisebox{4pt}{\footnotesize{\emph{\@title}}}}
\renewcommand{\headrulewidth}{0.4pt}
\fi
\fancyfoot[CE,CO]{\iffloatpage{}{\small{\thepage}}}

%----------------------
% Les titres de section
%----------------------
\titleformat{\section}
  {\normalfont\scshape\bfseries}{\thesection.}{1em}{}
\titleformat{\subsection}
  {\normalfont\bfseries}{\thesubsection.}{1em}{}
\titleformat{\subsubsection}%[block]
{\normalfont\itshape\bfseries}{\thesubsubsection.}{1em}{}
\titlespacing*{\section}      {0pt}{1.75ex plus 1ex minus .2ex}{0.5ex plus .2ex}
\titlespacing*{\subsection}   {0pt}{1.5ex plus 1ex minus .2ex}{0.3ex plus .2ex}
\titlespacing*{\subsubsection}{0pt}{1.25ex plus 1ex minus .2ex}{0.1ex plus .2ex}


%----------------------
% Les pages générées automatiquement
%----------------------
\renewcommand{\maketitle}{\setcounter{page}{3}
\ifFrenchcepii
\selectlanguage{french}
\fi}


% -------------------------
% environnement affiliation
% -------------------------
\newenvironment{affiliation}[1][]
    {%
    \clearpage
    \null
    {\vskip 3.5ex \@plus 1ex \@minus .2ex}
    \ifDraftcepii
    \begin{center}
    {\Large\textbf{{\textsc{#1}}}}%
    \else
    \begin{flushright}
    \textbf{{\textsc{#1}}}%
    \fi
    \vskip 3.5ex
    \setcounter{footnotememory}{\thefootnote}
    \setcounter{footnote}{0}
    \renewcommand\thefootnote{\@fnsymbol\c@footnote}
    }{%
    \ifDraftcepii
    \par
    This version: \today
    \end{center}
    \else
    \end{flushright}
    \fi
    {\vskip 3.5ex}
    \setcounter{footnote}{\thefootnotememory}
    }%

% ---------------------
% environnement de list
% ---------------------
\def\@listI{%
	\setlength{\leftmargin}{15pt}
  \topsep\z@
  \parsep 0.2ex
  \itemsep 0.3ex}
\let\@listi\@listI
\@listi
\def\@listii{\setlength{\leftmargin}{15pt}
   \labelwidth\leftmarginii\advance\labelwidth-\labelsep
   \topsep\z@ \parsep\z@ \itemsep\z@}
\def\@listiii{\setlength{\leftmargin}{15pt}
    \labelwidth\leftmarginiii\advance\labelwidth-\labelsep
    \topsep\z@ \parsep\z@ \itemsep\z@}
\partopsep=\z@


% -----------
% Les annexes
% -----------
\renewcommand\appendix{%
    \clearpage
    \phantomsection
    \ifFrenchcepii
    \section*{\hspace{0.4\textwidth}Annexes}
    \else
    \section*{\hspace{0.4\textwidth}Appendix}
    \fi
  	\addtocounter{section}{1}
  	\setcounter{subsection}{0}
  	\setcounter{table}{0}
  	\setcounter{figure}{0}
  	\gdef\thesubsection{\@Alph\c@subsection}
  	\gdef\thetable{\@Alph\c@subsection.\@arabic\c@table}
  	\gdef\thefigure{\@Alph\c@subsection.\@arabic\c@figure}
  	}

% ----------------
% La bibliographie
% ----------------
\renewenvironment{thebibliography}[1]{%
    \clearpage
    \phantomsection
    \ifFrenchcepii
    \section*{\hspace{0.4\textwidth}Bibliographie}
    \else
    \section*{\hspace{0.4\textwidth}References}
    \fi
  \list{}%
    {\small
     \setlength\labelwidth{0pt}%
     \setlength\labelsep{0pt}%
     \setlength\leftmargin{25pt}
     \setlength\itemindent{-25pt}
     \setlength\parsep\parskip
     \@openbib@code
     \usecounter{enumiv}%
     \let\p@enumiv\@empty
     \renewcommand\theenumiv{\@arabic\c@enumiv}}% 
  \sloppy
  \clubpenalty4000
  \@clubpenalty \clubpenalty
  \widowpenalty4000%
  \sfcode`\.\@m
  }


% ----------------
% Les grands flottants
% ----------------
\newenvironment{moremargin}[1]{\begin{list}{}{%
\setlength{\topsep}{0pt}%
\setlength{\leftmargin}{0pt}%
\setlength{\rightmargin}{0pt}%
\setlength{\listparindent}{\parindent}%
\setlength{\itemindent}{\parindent}%
\setlength{\parsep}{0pt plus 1pt}%
\addtolength{\leftmargin}{-#1}%
\addtolength{\rightmargin}{-#1}%
}\item }{\end{list}}

\endinput

