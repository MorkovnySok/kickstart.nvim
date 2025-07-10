-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
vim.deprecate = function() end
vim.opt.fixeol = false
vim.opt.colorcolumn = '120'

vim.opt.langmap = table.concat({
  'йq,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ъ],фa,ыs,вd,аf,пg,',
  "рh,оj,лk,дl,ж\\;,э',яz,чx,сc,мv,иb,тn,ьm,б\\,,ю.,",
  'ЙQ,ЦW,УE,КR,ЕT,НY,ГU,ШI,ЩO,ЗP,Х{,Ъ},ФA,ЫS,ВD,АF,ПG,',
  'РH,ОJ,ЛK,ДL,Ж:,Э",ЯZ,ЧX,СC,МV,ИB,ТN,ЬM,Б<,Ю>',
}, '')

return {
  'cohama/lexima.vim',
}
